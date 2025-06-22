import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarming_bapeltan/common/url.dart';

class Kontrol {
  // Get all controls for a device
  static Future<dynamic> getControlsByDevice(String deviceId,
      {String? authToken}) async {
    String apiURL = UrlData().url_controls + '?filter=(deviceId="$deviceId")';

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    // Add auth token if provided
    if (authToken != null) {
      header['Authorization'] = 'Bearer $authToken';
    }

    try {
      var apiResult = await http.get(
        Uri.parse(apiURL),
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      if (apiResult.statusCode == 200) {
        return {
          'success': true,
          'data': jsonObject['items'] ?? [],
          'totalItems': jsonObject['totalItems'] ?? 0
        };
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Failed to get controls'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Update control status (PocketBase format)
  static Future<dynamic> updateKontrolByStatus(
      int status, int idUser, int idAlat, int idKontrol,
      {String? authToken}) async {
    // First, find the control record by idKontrol and device
    String findURL = UrlData().url_controls + '?filter=(idKontrol=$idKontrol)';

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    if (authToken != null) {
      header['Authorization'] = 'Bearer $authToken';
    }

    try {
      // Find the control record
      var findResult = await http.get(
        Uri.parse(findURL),
        headers: header,
      );

      if (findResult.statusCode != 200) {
        return {'success': false, 'message': 'Control not found'};
      }

      var findData = json.decode(findResult.body);
      if (findData['items'].isEmpty) {
        return {
          'success': false,
          'message': 'Control with idKontrol $idKontrol not found'
        };
      }

      // Get the record ID
      String recordId = findData['items'][0]['id'];

      // Update the control
      String updateURL = UrlData().url_controls + '/records/$recordId';

      var body = jsonEncode({
        'isON': status == 1, // Convert int to boolean
        'updatedAt': DateTime.now().toIso8601String()
      });

      var apiResult = await http.patch(
        Uri.parse(updateURL),
        body: body,
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      if (apiResult.statusCode == 200) {
        return {
          'success': true,
          'data': jsonObject,
          'message': 'Control updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Failed to update control'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Legacy method for backward compatibility
  static Future<dynamic> updateKontrolByStatusLegacy(
      int status, int idUser, int idAlat, int idKontrol) async {
    return updateKontrolByStatus(status, idUser, idAlat, idKontrol);
  }

  // Create new control
  static Future<dynamic> createKontrol({
    required String deviceId,
    required int idKontrol,
    required String namaKontrol,
    required bool isON,
    String? authToken,
  }) async {
    String apiURL = UrlData().url_controls + '/records';

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    if (authToken != null) {
      header['Authorization'] = 'Bearer $authToken';
    }

    var body = jsonEncode({
      'deviceId': deviceId,
      'idKontrol': idKontrol,
      'namaKontrol': namaKontrol,
      'isON': isON,
    });

    try {
      var apiResult = await http.post(
        Uri.parse(apiURL),
        body: body,
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      if (apiResult.statusCode == 200) {
        return {
          'success': true,
          'data': jsonObject,
          'message': 'Control created successfully'
        };
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Failed to create control'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Update control automation status
  static Future<dynamic> updateKontrolByAuto(
      int status, int idUser, int idAlat, int idKontrol,
      {String? authToken}) async {
    // Find the control record first
    String findURL = UrlData().url_controls + '?filter=(idKontrol=$idKontrol)';

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    if (authToken != null) {
      header['Authorization'] = 'Bearer $authToken';
    }

    try {
      // Find the control record
      var findResult = await http.get(
        Uri.parse(findURL),
        headers: header,
      );

      if (findResult.statusCode != 200) {
        return {'success': false, 'message': 'Control not found'};
      }

      var findData = json.decode(findResult.body);
      if (findData['items'].isEmpty) {
        return {
          'success': false,
          'message': 'Control with idKontrol $idKontrol not found'
        };
      }

      // Get the record ID
      String recordId = findData['items'][0]['id'];

      // Update the control automation
      String updateURL = UrlData().url_controls + '/records/$recordId';

      var body = jsonEncode({
        'automated': status == 1, // Convert to boolean
        'updatedAt': DateTime.now().toIso8601String()
      });

      var apiResult = await http.patch(
        Uri.parse(updateURL),
        body: body,
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      if (apiResult.statusCode == 200) {
        return {'success': true, 'data': jsonObject, 'message': 'data updated'};
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Failed to update automation'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Update control parameter
  static Future<dynamic> updateKontrolByAutoParameter(
      String status, int idUser, int idAlat, int idKontrol,
      {String? authToken}) async {
    // Find the control record first
    String findURL = UrlData().url_controls + '?filter=(idKontrol=$idKontrol)';

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    if (authToken != null) {
      header['Authorization'] = 'Bearer $authToken';
    }

    try {
      // Find the control record
      var findResult = await http.get(
        Uri.parse(findURL),
        headers: header,
      );

      if (findResult.statusCode != 200) {
        return {'success': false, 'message': 'Control not found'};
      }

      var findData = json.decode(findResult.body);
      if (findData['items'].isEmpty) {
        return {
          'success': false,
          'message': 'Control with idKontrol $idKontrol not found'
        };
      }

      // Get the record ID
      String recordId = findData['items'][0]['id'];

      // Update the control parameter
      String updateURL = UrlData().url_controls + '/records/$recordId';

      var body = jsonEncode(
          {'parameter': status, 'updatedAt': DateTime.now().toIso8601String()});

      var apiResult = await http.patch(
        Uri.parse(updateURL),
        body: body,
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      if (apiResult.statusCode == 200) {
        return {'success': true, 'data': jsonObject, 'message': 'data updated'};
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Failed to update parameter'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }
}
