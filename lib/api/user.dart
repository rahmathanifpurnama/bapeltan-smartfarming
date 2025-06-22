import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarming_bapeltan/common/url.dart';
import 'package:smartfarming_bapeltan/model/user_model.dart';

class User {
  static UserModel? userModel;

  // Get user data by ID (PocketBase format)
  static Future<dynamic> getDataUser(String userId, {String? authToken}) async {
    try {
      String apiURL = UrlData().url_users + '/records/$userId';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var apiResult = await http.get(Uri.parse(apiURL), headers: header);

      if (apiResult.statusCode == 200) {
        var jsonObject = json.decode(apiResult.body);

        // Convert PocketBase format to legacy format
        var legacyFormat = {
          'user': [jsonObject] // Wrap in array for UserModel compatibility
        };

        userModel = UserModel.fromJson(legacyFormat);

        return {'success': true, 'data': jsonObject, 'model': userModel};
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get user data'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Legacy method for backward compatibility
  static getDataUserLegacy(int userId, {String? authToken}) async {
    return getDataUser(userId.toString(), authToken: authToken);
  }

  // Update user profile
  static Future<dynamic> updateUserProfile({
    required String userId,
    String? username,
    String? email,
    String? telepon,
    String? alamat,
    String? authToken,
  }) async {
    try {
      String apiURL = UrlData().url_users + '/records/$userId';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      Map<String, dynamic> updateData = {};
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (telepon != null) updateData['telepon'] = telepon;
      if (alamat != null) updateData['alamat'] = alamat;

      var body = jsonEncode(updateData);

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
          'message': 'Profile updated successfully'
        };
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Get user devices
  static Future<dynamic> getUserDevices(String userId,
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
          'message': errorData['message'] ?? 'Failed to get user devices'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Change password
  static Future<dynamic> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? authToken,
  }) async {
    try {
      String apiURL = UrlData().url_users + '/records/$userId';

      Map<String, String> header = {
        'Content-type': 'application/json',
      };

      if (authToken != null) {
        header['Authorization'] = 'Bearer $authToken';
      }

      var body = jsonEncode({
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': newPassword,
      });

      var apiResult = await http.patch(
        Uri.parse(apiURL),
        body: body,
        headers: header,
      );

      if (apiResult.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        var errorData = json.decode(apiResult.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to change password'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }
}
