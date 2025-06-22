// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/api/login.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/screens/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isShownPassword = false;
  bool _isVisibleLoading = false;
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'))),
                ),
                // const Icon(
                //   Icons.image,
                //   size: 100,
                // ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Silahkan Login',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Untuk mendapatkan kemudahan dalam mengelola tanaman anda hanya dari smartphone',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 35,
                ),

                /// KOLOM USERNAME
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(top: 10, left: 16, right: 16),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(
                              Icons.person,
                              color: Color.fromRGBO(153, 167, 153, 1.0),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Username tidak boleh kosong';
                            } else {
                              return null;
                            }
                          },
                        ),
                      ),

                      /// KOLOM PASSWORD
                      Container(
                        margin:
                            const EdgeInsets.only(top: 10, left: 16, right: 16),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isShownPassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: 'Kata Sandi',
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isShownPassword = !_isShownPassword;
                                });
                              },
                              child: Icon(
                                _isShownPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColor.hijau1,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color.fromRGBO(153, 167, 153, 1.0),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Kata Sandi tidak boleh kosong';
                            } else {
                              return null;
                            }
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      /// LOADING INDIKATOR
                      Visibility(
                        visible: _isVisibleLoading,
                        child: SpinKitRipple(
                          color: AppColor.hijau1,
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      /// TOMBOL LOGIN
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.hijau1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          onPressed: () async {
                            SharedPreferences pref =
                                await SharedPreferences.getInstance();

                            bool? isBlocked = pref.getBool('blocked');
                            if (isBlocked == null) {
                              isBlocked == false;
                            }

                            print("isBlocked");

                            if (_formKey.currentState!.validate() &&
                                !isBlocked!) {
                              /// show loading
                              setState(() {
                                _isVisibleLoading = true;
                              });

                              String username =
                                  _usernameController.text.toString();
                              String password =
                                  _passwordController.text.toString();

                              /// Login with username and password
                              var user =
                                  await Login.loginWithUsernameAndPassword(
                                username,
                                password,
                              ).timeout(
                                const Duration(minutes: 1),
                              );

                              /// hide loading
                              setState(() {
                                _isVisibleLoading = false;
                              });

                              /// kondisi untuk mengecek apakah berhasil login atau tidak
                              if (counter == 6) {
                                await _showAlertDialogByException(
                                    context,
                                    'Anda telah melakukan login yang salah secara terus menerus, silahkan hubungi Developer Aplikasi Bapeltan untuk meminta petunjuk!',
                                    'blocked');
                              } else if (user['success'] == true) {
                                // PocketBase success response
                                saveDataPocketBase(user, context);
                              } else {
                                counter++;
                                await _showAlertDialogByException(
                                    context,
                                    user['message'] ??
                                        'Username atau Kata sandi salah, silahkan input dengan benar',
                                    '');
                              }
                            } else if (isBlocked!) {
                              await _showAlertDialogByException(
                                  context,
                                  'Anda telah melakukan login yang salah secara terus menerus, silahkan hubungi Developer Aplikasi Bapeltan untuk meminta petunjuk!',
                                  'blocked');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveData(user, BuildContext context) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    await pref.setInt('id', user['0']['id']);
    await pref.setInt('idAlat', 1);
    await pref.setString('username', _usernameController.text.toString());
    await pref.setString('namaAlat', 'Modul 1');
    await pref.setBool('blocked', false);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      return Home();
    }), (route) => false);
  }

  // PocketBase version of saveData
  Future<void> saveDataPocketBase(user, BuildContext context) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    // PocketBase response format: user['user'] contains user data, user['token'] contains JWT
    var userData = user['user'];
    var authToken = user['token'];

    // Save user data from PocketBase response
    await pref.setString('userId', userData['id']); // PocketBase uses string ID
    await pref.setString('username',
        userData['username'] ?? _usernameController.text.toString());
    await pref.setString('email', userData['email'] ?? '');
    await pref.setString(
        'authToken', authToken); // Save JWT token for API calls
    await pref.setString('telepon', userData['telepon']?.toString() ?? '');
    await pref.setString('alamat', userData['alamat'] ?? '');

    // Legacy compatibility - set default values
    await pref.setInt('id', 1); // For backward compatibility with existing code
    await pref.setInt('idAlat', 1); // Default device ID
    await pref.setString('namaAlat', 'Modul 1'); // Default device name
    await pref.setString(
        'deviceId', 'default_device_id'); // Default device ID for PocketBase
    await pref.setBool('blocked', false);

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      return Home();
    }), (route) => false);
  }

  Future _showAlertDialogByException(
      BuildContext context, String message, String exception) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),
          backgroundColor: AppColor.hijau1,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (exception == '')
                    ? message + '\n\nKesalahan: $counter kali'
                    : message,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(
                height: 16,
              ),
              TextButton(
                onPressed: () async {
                  if (exception != 'blocked') {
                    Navigator.of(context).pop();
                  } else {
                    SharedPreferences pref =
                        await SharedPreferences.getInstance();

                    await pref.setBool('blocked', true);
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 250,
                  height: 50,
                  child: const Center(
                    child: Text(
                      'OKE',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        letterSpacing: 1,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          elevation: 10,
        );
      },
    );
  }

  Future<bool?> toast(String message) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColor.hijau1,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
