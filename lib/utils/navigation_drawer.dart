// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/api/realtime_data_drawer.dart';
import 'package:smartfarming_bapeltan/api/status_alat.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/screens/home.dart';
import 'package:smartfarming_bapeltan/screens/login_screen.dart';

class NavigationDrawer extends StatefulWidget {
  const NavigationDrawer({Key? key}) : super(key: key);

  @override
  State<NavigationDrawer> createState() => _NavigationDrawerState();
}

class _NavigationDrawerState extends State<NavigationDrawer> {
  int _clickItem = 1;
  int idTerpilih = 1;
  List jumlahData = [];
  List statusAlat = [];
  bool _isLoading = false;
  int idUser = 0;

  @override
  void initState() {
    super.initState();
    getIdAlat();
    getRealtimeDataDrawer();
  }

  void getIdAlat() async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    _clickItem = (pref.getInt('idAlat'))!;
    idUser = (pref.getInt('id'))!;
    idTerpilih = (pref.getInt('id')!);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColor.kuning,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(
              height: 100,
            ),
            Text(
              "Alatmu",
              style: TextStyle(
                fontSize: 30,
                color: AppColor.hijau2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Pilih alat yang\nmau ditampilkan datanya",
              style: TextStyle(
                color: AppColor.hijau2,
                fontWeight: FontWeight.bold,
              ),
            ),
            (_isLoading)
                ? Expanded(
                    child: const Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: SizedBox(
                            height: 40,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: jumlahData.length,
                      itemBuilder: (context, index) {
                        String? namaAlat = RealtimeDataDrawer
                            .model!.realtimeData![index].namaAlat;
                        int? idAlat = RealtimeDataDrawer
                            .model!.realtimeData![index].idAlat;

                        return buildListModule(
                          text: '$namaAlat',
                          status: (statusAlat[idAlat! - 1] == 1)
                              ? 'Online'
                              : 'Offline',
                          icon: Icons.circle,
                          idAlat: idAlat,
                          backgroundColor: (_clickItem == idAlat)
                              ? AppColor.hijau2
                              : AppColor.abu,
                        );
                      },
                    ),
                  ),
            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Divider(
                    color: Colors.grey,
                    thickness: 2,
                  ),
                  GestureDetector(
                    onTap: () {
                      /// konfirmasi logout
                      _showConfirmLogoutDialog();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontSize: 22,
                              color: AppColor.hijau2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons.logout,
                            color: AppColor.hijau1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget buildListModule({
    required String text,
    required String status,
    required IconData icon,
    required int? idAlat,
    required Color backgroundColor,
  }) {
    return InkWell(
      child: Container(
        margin: const EdgeInsets.only(
          top: 16,
          left: 5,
          right: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
          color: backgroundColor,
        ),
        child: ListTile(
          leading: Column(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/images/icon_alat.png'),
                backgroundColor: Colors.transparent,
              ),
              Container(
                height: 10,
                width: 10,
                // color: Colors.red,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: (status == 'Offline') ? AppColor.red : Colors.green),
              )
            ],
          ),
          title: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
      onTap: () async {
        SharedPreferences pref = await SharedPreferences.getInstance();

        setState(() {
          _clickItem = idAlat!;
        });

        await pref.setInt('idAlat', _clickItem);
        await pref.setString('namaAlat', text);
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
          return const Home();
        }), (route) => false);
      },
    );
  }

  Future<void> _showConfirmLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Log-out'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Apakah anda yakin ingin Log-out dari akun ini ?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('YA'),
              onPressed: () async {
                SharedPreferences pref = await SharedPreferences.getInstance();
                await pref.clear();
                Navigator.of(context, rootNavigator: true).pop('dialog');
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (context) {
                  return const LoginScreen();
                }), (route) => false);
              },
            ),
            TextButton(
              child: const Text('TIDAK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  getRealtimeDataDrawer() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      int userId = pref.getInt('id')!;
      await RealtimeDataDrawer.connectToApi(userId);
      jumlahData.addAll(RealtimeDataDrawer.model!.realtimeData!);

      getStatusAlat();
    } catch (e) {
      // Handle error silently or show user-friendly message
      setState(() {
        _isLoading = false;
      });
    }
  }

  void getStatusAlat() async {
    for (int i = 0; i < jumlahData.length; i++) {
      await StatusAlat.getStatusAlatByIdUserAndIdAlat(
        idUser,
        idTerpilih++,
      );
      statusAlat.add(StatusAlat.model!.status);
    }

    setState(() {
      _isLoading = false;
    });
  }
}
