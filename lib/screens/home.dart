// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartfarming_bapeltan/api/kontrol.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/common/icon_sensor.dart';
import 'package:smartfarming_bapeltan/common/kontrol_images.dart';
import 'package:smartfarming_bapeltan/model/user_model.dart';
import 'package:smartfarming_bapeltan/screens/login_screen.dart';
import 'package:smartfarming_bapeltan/utils/navigation_drawer.dart'
    as CustomDrawer;
import 'package:smartfarming_bapeltan/common/url.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late StreamController _dataRealtimeController;
  late StreamController _dataKontrol;
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  var tanggal = '';
  var jam = '';
  Timer? _pollingTimer;
  bool _isAppInForeground = true;

  Future<void> showDialogPesan(BuildContext context, String pesan) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pesan,
                    style: TextStyle(
                        color: AppColor.hijau1, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              InkWell(
                onTap: (() {
                  Navigator.of(context).pop();
                }),
                child: Container(
                  height: 40,
                  width: 100,
                  decoration: BoxDecoration(
                      color: AppColor.hijau1,
                      borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: Text(
                      "Ok",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }

  Future<void> showAutomationDialog(BuildContext context, int index,
      String parameterValue, String namaSensor) async {
    await showDialog(
        context: context,
        builder: (context) {
          final TextEditingController _textEditingController =
              TextEditingController(text: parameterValue);

          return AlertDialog(
            content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Setting Parameter Auto",
                        style: TextStyle(
                            color: AppColor.hijau1,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            width: 110,
                            height: 40,
                            child: Center(child: Text(namaSensor))),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "lebih dari",
                          style: TextStyle(
                              color: AppColor.hijau1,
                              fontWeight: FontWeight.w200),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Container(
                          height: 50,
                          width: 60,
                          // color: Colors.black,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            controller: _textEditingController,
                            validator: (value) {
                              if (value!.isNotEmpty) {
                                return null;
                              } else {
                                return "isi disini";
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ],
                )),
            actions: [
              TextButton(
                  onPressed: () {
                    putStatusKontrolAuto(0, index);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Matikan",
                    style: TextStyle(color: AppColor.hijau1),
                  )),
              InkWell(
                onTap: (() {
                  if (_formKey.currentState!.validate()) {
                    putStatusKontrolAuto(1, index);

                    String parameter = _textEditingController.text.toString();
                    putStatusKontrolParameter("$parameter", index);

                    Navigator.of(context).pop();
                  }
                }),
                child: Container(
                  height: 40,
                  width: 100,
                  decoration: BoxDecoration(
                      color: AppColor.hijau1,
                      borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: Text(
                      "Hidupkan",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }

  int count = 1;
  var linkImage = UrlData().url_images;
  var isDataLoading = false;
  int idAlat = 0;
  int idUser = 0;
  String username = '';
  String namaAlat = '';
  var listNamaSensor = [];

  // int jumlahData = 3;

  Future fetchRealtime({int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    try {
      isDataLoading = true;

      // Get auth token from SharedPreferences
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? authToken = pref.getString('authToken');
      String? deviceId = pref.getString('deviceId');

      // Use PocketBase API to get latest sensor data
      String apiURL = UrlData().url_sensor_data +
          '/records?filter=(deviceId="$deviceId")&sort=-timestamp&perPage=10';

      Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response =
          await http.get(Uri.parse(apiURL), headers: headers).timeout(
        Duration(seconds: 10), // Add timeout
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        // Convert PocketBase format to legacy format for compatibility
        var convertedItems = [];
        for (var item in jsonData['items'] ?? []) {
          convertedItems.add({
            'name': item['sensorType'] ?? 'Unknown Sensor',
            'value': item['value'] ?? 0,
            'unit': item['unit'] ?? '',
            'timestamp': item['timestamp'] ?? item['created'],
            'id': item['id']
          });
        }

        var legacyFormat = {
          'realtimeData': convertedItems,
          'totalItems': jsonData['totalItems'] ?? 0,
          'date': _formatDate(DateTime.now()),
          'time': _formatTime(DateTime.now())
        };

        return legacyFormat;
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be expired
        print('Authentication error: ${response.statusCode}');
        return {'realtimeData': [], 'totalItems': 0, 'error': 'auth_error'};
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error get data realtime (attempt ${retryCount + 1}): $e');

      // Retry logic
      if (retryCount < maxRetries &&
          (e is SocketException ||
              e is TimeoutException ||
              e is HttpException)) {
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return fetchRealtime(retryCount: retryCount + 1);
      }

      return {
        'realtimeData': [],
        'totalItems': 0,
        'error': e.toString(),
        'date': _formatDate(DateTime.now()),
        'time': _formatTime(DateTime.now())
      };
    } finally {
      isDataLoading = false;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  loadRealtime() async {
    fetchRealtime().then((res) async {
      _dataRealtimeController.add(res);
      return res;
    });
  }

  Future fetchKontrol({int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    try {
      isDataLoading = true;

      // Get auth token from SharedPreferences
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? authToken = pref.getString('authToken');
      String? deviceId = pref.getString('deviceId');

      // Use PocketBase API to get controls data
      String apiURL =
          UrlData().url_controls + '/records?filter=(deviceId="$deviceId")';

      Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response =
          await http.get(Uri.parse(apiURL), headers: headers).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        // Convert PocketBase format to legacy format for compatibility
        var convertedItems = [];
        for (var item in jsonData['items'] ?? []) {
          convertedItems.add({
            'name': item['namaKontrol'] ?? 'Unknown Control',
            'isON': item['isON'] == true ? 1 : 0, // Convert boolean to int
            'automated': item['automated'] == true ? 1 : 0,
            'parameter': item['parameter'] ?? '',
            'idKontrol': item['idKontrol'] ?? 0,
            'id': item['id']
          });
        }

        var legacyFormat = {
          'kontrol': convertedItems,
          'totalItems': jsonData['totalItems'] ?? 0
        };

        return legacyFormat;
      } else if (response.statusCode == 401) {
        print('Authentication error: ${response.statusCode}');
        return {'kontrol': [], 'totalItems': 0, 'error': 'auth_error'};
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error get data kontrol (attempt ${retryCount + 1}): $e');

      // Retry logic
      if (retryCount < maxRetries &&
          (e is SocketException ||
              e is TimeoutException ||
              e is HttpException)) {
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return fetchKontrol(retryCount: retryCount + 1);
      }

      return {'kontrol': [], 'totalItems': 0, 'error': e.toString()};
    } finally {
      isDataLoading = false;
    }
  }

  loadKontrol() async {
    fetchKontrol().then((res) async {
      _dataKontrol.add(res);
      return res;
    });
  }

  loadDateTime() {
    // DateTime is now handled within fetchRealtime to avoid duplicate API calls
    setState(() {
      tanggal = _formatDate(DateTime.now());
      jam = _formatTime(DateTime.now());
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBlockUser();
    _dataRealtimeController = new StreamController();
    _dataKontrol = new StreamController();
    getIdAlatFromSharedPref();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _dataRealtimeController.close();
    _dataKontrol.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _stopPolling();
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _stopPolling();
        break;
    }
  }

  void _startPolling() {
    _stopPolling(); // Stop any existing timer
    if (_isAppInForeground) {
      // Changed from 300ms to 5 seconds for better performance
      _pollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
        if (_isAppInForeground) {
          loadRealtime();
          loadKontrol();
          loadDateTime();
        }
      });
      // Load data immediately when starting
      loadRealtime();
      loadKontrol();
      loadDateTime();
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeigh = MediaQuery.of(context).size.height;
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Montserrat',
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: scaffoldKey,
        drawer: CustomDrawer.NavigationDrawer(),
        appBar: AppBar(
          backgroundColor: AppColor.hijau2,
          elevation: 0,
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 14,
                  ),
                  Text(
                    "Update pada $tanggal",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text("pukul $jam",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w400))
                ],
              ),
            )
          ],
        ),
        body: ListView(
          physics: ClampingScrollPhysics(),
          children: [
            // ATAS
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: AppColor.hijau2,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16))),
                  child: Row(
                    children: [
                      // SizedBox(
                      //   width: 20,
                      // ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ATAS
                          Padding(
                            padding: EdgeInsets.only(left: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi, $username",
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Selamat Datang di Kebunmu 😊",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 16,
                          ),
                          // KETERANGAN MODUL
                          Container(
                            padding: EdgeInsets.only(right: 20),
                            width: screenWidth * 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  namaAlat,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: AppColor.kuning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ISI SENSOR

                StreamBuilder<dynamic>(
                    stream: _dataRealtimeController.stream,
                    builder: (context, snapshot) {
                      // print('Has error: ${snapshot.hasError}');
                      // print('Has data: ${snapshot.hasData}');
                      // print('Snapshot Data ${snapshot.data}');

                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      } else if (snapshot.hasData) {
                        var fotoIkon = "";
                        var jumlahData = snapshot.data['realtimeData'].length;
                        var dataRealtime = snapshot.data['realtimeData'];
                        return Container(
                          margin: EdgeInsets.fromLTRB(12, 100, 12, 12),
                          padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
                          // Setting supaya container dinamis menyesuaikanb isi data sensor non null yang ditampilkan
                          height: jumlahData == 1 || jumlahData == 2
                              ? 110
                              : jumlahData == 3 || jumlahData == 4
                                  ? 200
                                  : jumlahData == 5 || jumlahData == 6
                                      ? 290
                                      : jumlahData == 7 || jumlahData == 8
                                          ? 380
                                          : 470,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: StaggeredGrid.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: List.generate(jumlahData, (index) {
// TODO: LOGIKA FOTO IKON
                              if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "suhu udara") {
                                fotoIkon = IconSensor.foto_suhu;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "suhu air") {
                                fotoIkon = IconSensor.foto_suhu_air;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "suhu tanah") {
                                fotoIkon = IconSensor.foto_suhu_tanah;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "ppm air") {
                                fotoIkon = IconSensor.foto_ppm_air;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "ph tanah") {
                                fotoIkon = IconSensor.foto_ph_tanah;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "ph air") {
                                fotoIkon = IconSensor.foto_ph_air;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "kelembapan tanah") {
                                fotoIkon = IconSensor.foto_kelembaban_tanah;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "intensitas cahaya") {
                                fotoIkon = IconSensor.foto_intensitas_cahaya;
                              } else if (dataRealtime[index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "kelembapan udara") {
                                fotoIkon = IconSensor.foto_humidity;
                              } else {
                                fotoIkon = IconSensor.foto_lainnya;
                              }

                              return StaggeredGridTile.count(
                                crossAxisCellCount: 1,
                                mainAxisCellCount: 1,
                                child: InkWell(
// KLIK PADA SENSOR

                                  onTap: () {},
                                  child: Container(
                                      //  color: Colors.yellow,
                                      height: 78,
                                      width: 156,
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 3,
                                              blurRadius: 5,
                                              offset: Offset(0,
                                                  3), // changes position of shadow
                                            ),
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: AppColor.kuning),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.only(left: 26),
                                            child: Text(
                                              dataRealtime[index]['name'],
                                              // "Nama Sensor",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 2,
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 10,
                                              ),
                                              // CircleAvatar(
                                              //   backgroundColor: Colors.black,
                                              // ),
                                              Container(
                                                height: 40,
                                                width: 40,
                                                // color: Colors.black,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: AssetImage(
                                                            fotoIkon),
                                                        // NetworkImage(
                                                        //     linkImage +
                                                        //         dataRealtime[
                                                        //                 index]
                                                        //             ['image']
                                                        //             ),
                                                        fit: BoxFit.cover)),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Container(
                                                  //   child: Text(
                                                  //     dataRealtime[index]['name'],
                                                  //     // "Nama Sensor",
                                                  //     style: TextStyle(
                                                  //         fontSize: 10,
                                                  //         fontWeight:
                                                  //             FontWeight.bold),
                                                  //   ),
                                                  // ),
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 12,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            // color: AppColor.hijau3,
                                                            height: 34,
                                                            child: Text(
                                                              dataRealtime[
                                                                          index]
                                                                      ['value']
                                                                  .toString(),
                                                              // "1000",
                                                              style: TextStyle(
                                                                  fontSize: 30,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColor
                                                                      .hijau1),
                                                            ),
                                                          ),
                                                          Container(
                                                              height: 18,
                                                              // color: Colors.amber,
                                                              child: Text(
                                                                  dataRealtime[
                                                                          index]
                                                                      [
                                                                      'unit'])),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ],
                                      )),
                                ),
                              );
                            }),
                          ),
                        );
                      } else if (snapshot.connectionState !=
                          ConnectionState.done) {
                        // LOADING SENSOR
                        return Container(
                            margin: EdgeInsets.fromLTRB(12, 100, 12, 12),
                            padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
                            // Setting supaya container dinamis menyesuaikanb isi data sensor non null yang ditampilkan
                            height: 110,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: StaggeredGrid.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: List.generate(2, (index) {
                                // print(snapshot.data['realtimeData'].length);
                                return StaggeredGridTile.count(
                                  crossAxisCellCount: 1,
                                  mainAxisCellCount: 1,
                                  child: Container(
                                      //  color: Colors.yellow,
                                      height: 78,
                                      width: 156,
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 3,
                                              blurRadius: 5,
                                              offset: Offset(0,
                                                  3), // changes position of shadow
                                            ),
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.grey[100]),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          // CircleAvatar(
                                          //   backgroundColor: Colors.black,
                                          // ),
                                          Container(
                                            height: 40,
                                            width: 40,
                                            // color: Colors.black,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 10,
                                                width: 50,
                                                // color: Colors.amber,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        height: 8,
                                                      ),
                                                      Container(
                                                        // color: AppColor.hijau3,
                                                        height: 34,
                                                        width: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 6,
                                                      ),
                                                      Container(
                                                        height: 10,
                                                        width: 20,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              )
                                            ],
                                          )
                                        ],
                                      )),
                                );
                              }),
                            ));
                      } else if (!snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.done) {
                        return Expanded(
                            child: Center(child: Text('Tidak Ada Data')));
                      } else {
                        return Expanded(
                            child: Center(child: Text('Tidak Ada Data')));
                      }
                    }),
              ],
            ),

            // OTOMATIS atau MANUAL

            Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.only(left: 18),
              // height: 40,

              child: Text(
                "Kontrol Tersedia",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.hijau1),
              ),
            ),

            // KONTROL

            StreamBuilder<dynamic>(
                stream: _dataKontrol.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  } else if (snapshot.hasData) {
                    var jumlahKontrol = snapshot.data['kontrol'].length;
                    var dataKontrol = snapshot.data['kontrol'];
                    var status = '';
                    var fotoSaklar = '';
                    var foto_on = '';
                    var foto_off = '';
                    var status_foto = '';

                    return Container(
                        height: jumlahKontrol == 1
                            ? screenHeigh * 0.23
                            : jumlahKontrol == 2
                                ? screenHeigh * 0.46
                                : jumlahKontrol == 3
                                    ? screenHeigh * 0.66
                                    : jumlahKontrol == 4
                                        ? screenHeigh * 0.89
                                        : jumlahKontrol == 5
                                            ? screenHeigh * 1.09
                                            : screenHeigh * 0.2,
                        // height: 400,
                        // width: Get.width * 0.8,
                        // color: Colors.black,
                        child: ListView.builder(
                          padding: EdgeInsets.only(top: 6),
                          physics: NeverScrollableScrollPhysics(),
                          // padding: EdgeInsets.all(12),
                          itemCount: jumlahKontrol,
                          itemBuilder: (context, index) {
                            // CHECKING FOTO

                            if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'sprinkler') {
                              foto_on = KontrolImages.sprinkler_on;
                              foto_off = KontrolImages.sprinkler_off;
                            } else if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'drip') {
                              foto_on = KontrolImages.drip_on;
                              foto_off = KontrolImages.drip_off;
                            } else if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'kipas angin') {
                              foto_on = KontrolImages.kipas_on;
                              foto_off = KontrolImages.kipas_off;
                            } else if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'mist') {
                              foto_on = KontrolImages.mist_on;
                              foto_off = KontrolImages.mist_off;
                            } else if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'valve') {
                              foto_on = KontrolImages.valve_on;
                              foto_off = KontrolImages.valve_off;
                            } else if (dataKontrol[index]['name']
                                    .toString()
                                    .toLowerCase() ==
                                'pompa') {
                              foto_on = KontrolImages.pompa_on;
                              foto_off = KontrolImages.pompa_off;
                            } else {
                              foto_on = KontrolImages.lainnya_on;
                              foto_off = KontrolImages.lainnya_off;
                            }

                            // CHECKING ON OFF

                            if (dataKontrol[index]['isON'] == 0) {
                              status = 'OFF';
                              fotoSaklar = 'assets/images/saklar_off.png';
                              status_foto = foto_off;
                            } else if (dataKontrol[index]['isON'] == 1) {
                              status = 'ON';
                              fotoSaklar = 'assets/images/saklar_on.png';
                              status_foto = foto_on;
                            } else {
                              status = '';
                              fotoSaklar = '';
                            }

                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(26, 6, 26, 6),
                                  // height: Get.height * 0.2,
                                  height: screenHeigh * 0.2,
                                  // height: 180,
                                  // width: 200,
                                  //  color: Colors.white,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[200]),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 8,
                                        child: Stack(
                                          children: [
                                            Container(
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: AssetImage(
                                                            status_foto),
                                                        fit: BoxFit.cover),
                                                    // color: AppColor.hijau2,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12))),
                                            Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      Text(
                                                        dataKontrol[index]
                                                            ['name'],
                                                        style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            foreground: Paint()
                                                              ..style =
                                                                  PaintingStyle
                                                                      .stroke
                                                              ..strokeWidth = 5
                                                              ..color = AppColor
                                                                  .kuning),
                                                      ),
                                                      Text(
                                                          dataKontrol[index]
                                                              ['name'],
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            // color:
                                                            //     AppColor.hijau1
                                                          ))
                                                    ],
                                                  ),
                                                  Stack(
                                                    children: [
                                                      Text(
                                                        dataKontrol[index]
                                                            ['subname'],
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            foreground: Paint()
                                                              ..style =
                                                                  PaintingStyle
                                                                      .stroke
                                                              ..strokeWidth = 5
                                                              ..color = AppColor
                                                                  .kuning),
                                                      ),
                                                      Text(
                                                          dataKontrol[index]
                                                              ['subname'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            // color:
                                                            //     AppColor.hijau1
                                                          ))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  20, 0, 0, 20),
                                              child: Align(
                                                alignment: Alignment.bottomLeft,
                                                child: InkWell(
                                                  onTap: () async {
                                                    print(
                                                        "auto indek ke ${index + 1} ditekan");
                                                    if (dataKontrol[index]
                                                                    ['sensor']
                                                                .toString()
                                                                .toLowerCase() ==
                                                            "null" ||
                                                        dataKontrol[index]
                                                                    ['sensor']
                                                                .toString()
                                                                .toLowerCase() ==
                                                            "") {
                                                      showDialogPesan(context,
                                                          "Mode Automatis tidak tersedia pada kontrol ini");
                                                    } else {
                                                      await showAutomationDialog(
                                                          context,
                                                          index + 1,
                                                          dataKontrol[index]
                                                                  ['parameter']
                                                              .toString(),
                                                          dataKontrol[index]
                                                                  ['sensor']
                                                              .toString());
                                                    }
                                                  },
                                                  child: Container(
                                                    height: 40,
                                                    width: 40,
                                                    // color: Colors.black,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          image: AssetImage(
                                                              'assets/images/kontrol/icon_auto.png'),
                                                          fit: BoxFit.cover),
                                                      color: (dataKontrol[index]
                                                                  [
                                                                  'automated'] ==
                                                              1)
                                                          ? AppColor.hijau3
                                                          : AppColor.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 120, bottom: 30),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Stack(
                                                        children: [
                                                          Text(
                                                            status,
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                foreground:
                                                                    Paint()
                                                                      ..style =
                                                                          PaintingStyle
                                                                              .stroke
                                                                      ..strokeWidth =
                                                                          5
                                                                      ..color =
                                                                          AppColor
                                                                              .kuning),
                                                          ),
                                                          Text(status,
                                                              style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ))
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(26, 6, 26, 6),
                                      // height: Get.height * 0.2,
                                      // height: 150,
                                      height: screenHeigh * 0.2,
                                      width: 107,
                                      // color: Colors.yellow,
                                      child: Container(
                                        margin: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            // color: Colors.black,
                                            image: DecorationImage(
                                                image: AssetImage(fotoSaklar),
                                                fit: BoxFit.cover),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Column(
                                          children: [
                                            Expanded(
                                                flex: 1,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (dataKontrol[index]
                                                            ['automated'] ==
                                                        0) {
                                                      print(
                                                          "tombol ON index ke $index ditekan");
                                                      putStatusKontrol(
                                                          1, index + 1);
                                                    } else {
                                                      showDialogPesan(context,
                                                          "Kontrol berada di mode Automatis");
                                                    }
                                                  },
                                                  child: Container(
                                                    color: Colors.transparent,
                                                  ),
                                                )),
                                            Expanded(
                                                flex: 1,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (dataKontrol[index]
                                                            ['automated'] ==
                                                        0) {
                                                      print(
                                                          "tombol OFF index ke $index ditekan");
                                                      putStatusKontrol(
                                                          0, index + 1);
                                                    } else {
                                                      showDialogPesan(context,
                                                          "Kontrol berada di mode Automatis");
                                                    }
                                                  },
                                                  child: Container(
                                                    color: Colors.transparent,
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ));
                  } else if (snapshot.connectionState != ConnectionState.done) {
                    return Column(
                      children: [
                        Container(
                            margin: EdgeInsets.fromLTRB(20, 10, 20, 12),
                            // padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                            // Setting supaya container dinamis menyesuaikanb isi data sensor non null yang ditampilkan
                            height: 150,
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12)),
                            child: Stack(
                              children: [
                                Container(
                                  height: screenHeigh * 0.2,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      // height: Get.height * 0.2,
                                      // height: 150,
                                      margin: EdgeInsets.all(12),
                                      height: screenHeigh * 0.2,
                                      width: 80,
                                      // color: Colors.yellow,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(18, 18, 0, 0),
                                  height: 34,
                                  width: 100,
                                  // color: Colors.black,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(140, 80, 0, 0),
                                  height: 34,
                                  width: 80,
                                  // color: Colors.black,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            )),
                        Container(
                            margin: EdgeInsets.fromLTRB(20, 10, 20, 12),
                            // padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                            // Setting supaya container dinamis menyesuaikanb isi data sensor non null yang ditampilkan
                            height: 150,
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12)),
                            child: Stack(
                              children: [
                                Container(
                                  height: screenHeigh * 0.2,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      // height: Get.height * 0.2,
                                      // height: 150,
                                      margin: EdgeInsets.all(12),
                                      height: screenHeigh * 0.2,
                                      width: 80,
                                      // color: Colors.yellow,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(18, 18, 0, 0),
                                  height: 34,
                                  width: 100,
                                  // color: Colors.black,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(140, 80, 0, 0),
                                  height: 34,
                                  width: 80,
                                  // color: Colors.black,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    );
                  } else if (!snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.done) {
                    return Text('Data Tidak Ada');
                  } else {
                    return Text('Offline');
                  }
                }),
          ],
        ),
      ),
    );
  }

  Future<void> getIdAlatFromSharedPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    idUser = (pref.getInt('id'))!;
    idAlat = (pref.getInt('idAlat'))!;
    username = (pref.getString('username'))!;
    namaAlat = (pref.getString('namaAlat'))!;
    setState(() {});
  }

  void putStatusKontrol(int i, int index) async {
    // Get auth token from SharedPreferences
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? authToken = pref.getString('authToken');

    var putKontrolStatus = await Kontrol.updateKontrolByStatus(
        i, idUser, idAlat, index,
        authToken: authToken);

    if (putKontrolStatus['message'] == 'data updated') {
      setState(() {
        print('updated kontrol status to $i');
      });
    }
  }

  void putStatusKontrolAuto(int i, int index) async {
    // Get auth token from SharedPreferences
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? authToken = pref.getString('authToken');

    var putKontrolStatus = await Kontrol.updateKontrolByAuto(
        i, idUser, idAlat, index,
        authToken: authToken);

    if (putKontrolStatus['message'] == 'data updated') {
      setState(() {
        print('updated alat ke $index auto to $i');
      });
    }
  }

  void putStatusKontrolParameter(String param, int index) async {
    // Get auth token from SharedPreferences
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? authToken = pref.getString('authToken');

    var putKontrolStatus = await Kontrol.updateKontrolByAutoParameter(
        param, idUser, idAlat, index,
        authToken: authToken);

    if (putKontrolStatus['message'] == 'data updated') {
      setState(() {
        print('updated isi parameter auto alat ke $index auto to $param');
      });
    }
  }

  Future<void> _checkBlockUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    bool? isBlocked = pref.getBool('blocked');
    if (isBlocked!) {
      await _showAlertDialogByException(
        context,
        'Anda telah melakukan login yang salah secara terus menerus, silahkan hubungi Developer Aplikasi Bapeltan untuk meminta petunjuk!',
      );
    }
  }

  Future _showAlertDialogByException(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) {
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
                message,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(
                height: 16,
              ),
              TextButton(
                onPressed: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  await pref.clear();

                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) {
                    return const LoginScreen();
                  }), (route) => false);
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

  // void getNamaUser() async {
  //   await
  // }
}
