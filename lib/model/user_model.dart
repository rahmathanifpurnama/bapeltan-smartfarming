import 'dart:convert';

/// Kelas khusus untuk model data user
class UserModel {
  List<User>? user;

  UserModel({this.user});

  UserModel.fromJson(Map<String, dynamic> json) {
    if (json['user'] != null) {
      user = <User>[];
      json['user'].forEach((v) {
        user!.add(new User.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.user != null) {
      data['user'] = this.user!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class User {
  String? email;
  String? username;
  String? password;
  int? telepon;
  String? alamat;
  String? idUnique;

  User(
      {this.email,
      this.username,
      this.password,
      this.telepon,
      this.alamat,
      this.idUnique});

  User.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    username = json['username'];
    password = json['password'];
    telepon = json['telepon'];
    alamat = json['alamat'];
    idUnique = json['idUnique'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['username'] = this.username;
    data['password'] = this.password;
    data['telepon'] = this.telepon;
    data['alamat'] = this.alamat;
    data['idUnique'] = this.idUnique;
    return data;
  }
}
