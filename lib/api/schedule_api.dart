// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/common/url.dart';
import 'package:smartfarming_bapeltan/model/schedule_model.dart';

class ScheduleApi {
  static const String _schedulesEndpoint = '/api/collections/schedules';
  static const String _automationRulesEndpoint =
      '/api/collections/automation_rules';
  static const String _scheduleExecutionsEndpoint =
      '/api/collections/schedule_executions';

  // Get base URL from UrlData
  String get _baseUrl => UrlData().url_sensor_data.split('/api/collections')[0];

  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? authToken = pref.getString('authToken');

    Map<String, String> headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Future<String?> _getDeviceId() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? deviceId = pref.getString('deviceId');

      // If no deviceId in SharedPreferences, try to get from devices collection
      if (deviceId == null || deviceId.isEmpty) {
        String? authToken = pref.getString('authToken');
        if (authToken != null) {
          // Get first device for current user
          String apiURL =
              '${_baseUrl}/api/collections/devices/records?perPage=1';

          Map<String, String> headers = {
            "Accept": "application/json",
            "Authorization": "Bearer $authToken",
          };

          final response = await http.get(Uri.parse(apiURL), headers: headers);

          if (response.statusCode == 200) {
            var jsonData = json.decode(response.body);
            if (jsonData['items'] != null && jsonData['items'].isNotEmpty) {
              deviceId = jsonData['items'][0]['id'];
              // Save to SharedPreferences for future use
              await pref.setString('deviceId', deviceId!);
            }
          }
        }
      }

      return deviceId ?? '016j4islabono91'; // Fallback to sample device ID
    } catch (e) {
      print('Error getting device ID: $e');
      return '016j4islabono91'; // Fallback to sample device ID
    }
  }

  // Schedule Management Methods
  Future<List<ScheduleModel>> getSchedules() async {
    try {
      String? deviceId = await _getDeviceId();
      String apiURL =
          '$_baseUrl$_schedulesEndpoint/records?filter=(deviceId="$deviceId")&sort=-created';

      Map<String, String> headers = await _getHeaders();

      final response =
          await http.get(Uri.parse(apiURL), headers: headers).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<ScheduleModel> schedules = [];

        for (var item in jsonData['items'] ?? []) {
          try {
            schedules.add(ScheduleModel.fromJson(item));
          } catch (e) {
            print('Error parsing schedule: $e');
          }
        }

        return schedules;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  Future<ScheduleModel?> createSchedule(ScheduleModel schedule) async {
    try {
      String apiURL = '$_baseUrl$_schedulesEndpoint/records';
      Map<String, String> headers = await _getHeaders();

      Map<String, dynamic> body = schedule.toJson();
      body['deviceId'] = _getDeviceId();

      final response = await http
          .post(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(body),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonData = json.decode(response.body);
        return ScheduleModel.fromJson(jsonData);
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error creating schedule: $e');
      return null;
    }
  }

  Future<ScheduleModel?> updateSchedule(ScheduleModel schedule) async {
    try {
      String apiURL = '$_baseUrl$_schedulesEndpoint/records/${schedule.id}';
      Map<String, String> headers = await _getHeaders();

      Map<String, dynamic> body = schedule.toJson();

      final response = await http
          .patch(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(body),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return ScheduleModel.fromJson(jsonData);
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error updating schedule: $e');
      return null;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      String apiURL = '$_baseUrl$_schedulesEndpoint/records/$scheduleId';
      Map<String, String> headers = await _getHeaders();

      final response = await http
          .delete(
        Uri.parse(apiURL),
        headers: headers,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  Future<bool> toggleSchedule(String scheduleId, bool isActive) async {
    try {
      String apiURL = '$_baseUrl$_schedulesEndpoint/records/$scheduleId';
      Map<String, String> headers = await _getHeaders();

      Map<String, dynamic> body = {
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await http
          .patch(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(body),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling schedule: $e');
      return false;
    }
  }

  // Automation Rules Methods
  Future<List<AutomationRule>> getAutomationRules() async {
    try {
      String? deviceId = await _getDeviceId();
      String apiURL =
          '$_baseUrl$_automationRulesEndpoint/records?filter=(deviceId="$deviceId")&sort=-created';

      Map<String, String> headers = await _getHeaders();

      final response =
          await http.get(Uri.parse(apiURL), headers: headers).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<AutomationRule> rules = [];

        for (var item in jsonData['items'] ?? []) {
          try {
            rules.add(AutomationRule.fromJson(item));
          } catch (e) {
            print('Error parsing automation rule: $e');
          }
        }

        return rules;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching automation rules: $e');
      return [];
    }
  }

  Future<AutomationRule?> createAutomationRule(AutomationRule rule) async {
    try {
      String apiURL = '$_baseUrl$_automationRulesEndpoint/records';
      Map<String, String> headers = await _getHeaders();

      Map<String, dynamic> body = rule.toJson();
      body['deviceId'] = _getDeviceId();

      final response = await http
          .post(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(body),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonData = json.decode(response.body);
        return AutomationRule.fromJson(jsonData);
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error creating automation rule: $e');
      return null;
    }
  }

  Future<bool> deleteAutomationRule(String ruleId) async {
    try {
      String apiURL = '$_baseUrl$_automationRulesEndpoint/records/$ruleId';
      Map<String, String> headers = await _getHeaders();

      final response = await http
          .delete(
        Uri.parse(apiURL),
        headers: headers,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting automation rule: $e');
      return false;
    }
  }

  // Schedule Execution Methods
  Future<List<ScheduleExecution>> getScheduleExecutions(
      String scheduleId) async {
    try {
      String apiURL =
          '$_baseUrl$_scheduleExecutionsEndpoint/records?filter=(scheduleId="$scheduleId")&sort=-executedAt&perPage=50';

      Map<String, String> headers = await _getHeaders();

      final response =
          await http.get(Uri.parse(apiURL), headers: headers).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<ScheduleExecution> executions = [];

        for (var item in jsonData['items'] ?? []) {
          try {
            executions.add(ScheduleExecution.fromJson(item));
          } catch (e) {
            print('Error parsing schedule execution: $e');
          }
        }

        return executions;
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching schedule executions: $e');
      return [];
    }
  }

  Future<bool> logScheduleExecution(ScheduleExecution execution) async {
    try {
      String apiURL = '$_baseUrl$_scheduleExecutionsEndpoint/records';
      Map<String, String> headers = await _getHeaders();

      final response = await http
          .post(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(execution.toJson()),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error logging schedule execution: $e');
      return false;
    }
  }
}
