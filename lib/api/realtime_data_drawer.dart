import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarming_bapeltan/common/url.dart';
import 'package:smartfarming_bapeltan/model/realtime_data_drawer_model.dart';

class RealtimeDataDrawer {
  static RealtimeDataDrawerModel? model;

  // Legacy method for backward compatibility
  static connectToApi(int userId, {String? authToken}) async {
    return getRealtimeDataDrawer(userId, authToken: authToken);
  }

  // Get realtime data for drawer/navigation (PocketBase format)
  static Future<dynamic> getRealtimeDataDrawer(int idUser,
      {String? authToken}) async {
    try {
      // Get devices for the user first
      String devicesURL =
          UrlData().url_devices + '/records?filter=(userId="$idUser")';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var devicesResult =
          await http.get(Uri.parse(devicesURL), headers: header);

      if (devicesResult.statusCode == 200) {
        var devicesData = json.decode(devicesResult.body);

        if (devicesData['items'].isNotEmpty) {
          // Convert to legacy format for compatibility
          var realtimeDataList = [];

          for (var device in devicesData['items']) {
            realtimeDataList.add({
              'idAlat': device['idAlat'],
              'namaAlat': device['namaAlat'],
              'updatedAt': device['updated'] ?? device['created']
            });
          }

          var legacyFormat = {'realtimeData': realtimeDataList};

          model = RealtimeDataDrawerModel.fromJson(legacyFormat);

          return {
            'success': true,
            'data': devicesData['items'],
            'model': model
          };
        } else {
          return {'success': false, 'message': 'No devices found for user'};
        }
      } else {
        var errorData = json.decode(devicesResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get devices'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Get sensor data for specific device
  static Future<dynamic> getSensorDataByDevice(String deviceId,
      {String? authToken, int? limit}) async {
    try {
      String apiURL = UrlData().url_sensor_data +
          '/records?filter=(deviceId="$deviceId")&sort=-created';

      if (limit != null) {
        apiURL += '&perPage=$limit';
      }

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var apiResult = await http.get(Uri.parse(apiURL), headers: header);

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        return {
          'success': true,
          'data': jsonObject['items'] ?? [],
          'totalItems': jsonObject['totalItems'] ?? 0
        };
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get sensor data'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Get latest sensor readings for dashboard
  static Future<dynamic> getLatestSensorData(String deviceId,
      {String? authToken}) async {
    try {
      String apiURL = UrlData().url_sensor_data +
          '/records?filter=(deviceId="$deviceId")&sort=-timestamp&perPage=10';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var apiResult = await http.get(Uri.parse(apiURL), headers: header);

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        // Group by sensor type for easy access
        Map<String, dynamic> groupedData = {};

        for (var item in jsonObject['items']) {
          String sensorType = item['sensorType'];
          if (!groupedData.containsKey(sensorType)) {
            groupedData[sensorType] = item;
          }
        }

        return {
          'success': true,
          'data': jsonObject['items'],
          'grouped': groupedData,
          'totalItems': jsonObject['totalItems'] ?? 0
        };
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get latest sensor data'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }
}
