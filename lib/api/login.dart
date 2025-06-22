import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarming_bapeltan/common/url.dart';

class Login {
  static Future<dynamic> loginWithUsernameAndPassword(
      String username, String password) async {
    String apiURL = UrlData().url_login;

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    // PocketBase authentication format
    var body = jsonEncode({
      'identity': username, // PocketBase uses 'identity' instead of 'username'
      'password': password
    });

    try {
      var apiResult = await http.post(
        Uri.parse(apiURL),
        body: body,
        headers: header,
      );

      var jsonObject = json.decode(apiResult.body);

      // PocketBase returns different structure
      if (apiResult.statusCode == 200) {
        // Success - return user data and token
        return {
          'success': true,
          'user': jsonObject['record'],
          'token': jsonObject['token'],
          'message': 'Login successful'
        };
      } else {
        // Error - return error message
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Login failed',
          'data': jsonObject
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  // Register new user (bonus feature)
  static Future<dynamic> registerUser({
    required String username,
    required String email,
    required String password,
    String? telepon,
    String? alamat,
  }) async {
    String apiURL = UrlData().url_register;

    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    var body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'telepon': telepon,
      'alamat': alamat,
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
          'user': jsonObject,
          'message': 'Registration successful'
        };
      } else {
        return {
          'success': false,
          'message': jsonObject['message'] ?? 'Registration failed',
          'data': jsonObject
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }
}
