import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarming_bapeltan/common/url.dart';
import 'package:smartfarming_bapeltan/model/status_alat_model.dart';

class StatusAlat {
  static StatusAlatModel? model;

  // Get device status by device ID (PocketBase format)
  static Future<dynamic> getStatusAlatByIdUserAndIdAlat(int idUser, int idAlat,
      {String? authToken}) async {
    try {
      // Query devices collection with filter
      String apiURL =
          UrlData().url_devices + '/records?filter=(idAlat=$idAlat)';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var apiResult = await http.get(Uri.parse(apiURL), headers: header);

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        if (jsonObject['items'].isNotEmpty) {
          var deviceData = jsonObject['items'][0];

          // Convert PocketBase format to legacy format
          var legacyFormat = {
            'id': deviceData['id'],
            'idUser': idUser,
            'idAlat': deviceData['idAlat'],
            'status': deviceData['status']
          };

          model = StatusAlatModel.fromJson(legacyFormat);

          return {'success': true, 'data': deviceData, 'model': model};
        } else {
          return {'success': false, 'message': 'Device not found'};
        }
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get device status'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Get all devices for a user
  static Future<dynamic> getDevicesByUser(String userId,
      {String? authToken}) async {
    try {
      String apiURL =
          UrlData().url_devices + '/records?filter=(userId="$userId")';

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
          'message': errorData['message'] ?? 'Failed to get devices'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Update device status
  static Future<dynamic> updateDeviceStatus(String deviceId, int status,
      {String? authToken}) async {
    try {
      String apiURL = UrlData().url_devices + '/records/$deviceId';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var body = jsonEncode(
          {'status': status, 'updatedAt': DateTime.now().toIso8601String()});

      var apiResult = await http.patch(
        Uri.parse(apiURL),
        body: body,
        headers: header,
      );

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        return {
          'success': true,
          'data': jsonObject,
          'message': 'Device status updated successfully'
        };
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update device status'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Create new device
  static Future<dynamic> createDevice({
    required String userId,
    required int idAlat,
    required String namaAlat,
    required int status,
    String? lokasi,
    String? authToken,
  }) async {
    try {
      String apiURL = UrlData().url_devices + '/records';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var body = jsonEncode({
        'userId': userId,
        'idAlat': idAlat,
        'namaAlat': namaAlat,
        'status': status,
        'lokasi': lokasi,
      });

      var apiResult = await http.post(
        Uri.parse(apiURL),
        body: body,
        headers: header,
      );

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        return {
          'success': true,
          'data': jsonObject,
          'message': 'Device created successfully'
        };
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create device'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }
}
