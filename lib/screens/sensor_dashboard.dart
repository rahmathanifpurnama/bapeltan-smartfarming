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
import 'package:smartfarming_bapeltan/common/url.dart';

class SensorDashboard extends StatefulWidget {
  const SensorDashboard({Key? key}) : super(key: key);

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard>
    with WidgetsBindingObserver {
  late StreamController _dataRealtimeController;
  late StreamController _dataKontrol;
  final _formKey = GlobalKey<FormState>();
  Timer? _pollingTimer;
  bool _isAppInForeground = true;

  var tanggal = '';
  var jam = '';
  bool isDataLoading = false;
  String username = '';
  String namaAlat = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dataRealtimeController = StreamController();
    _dataKontrol = StreamController();
    _loadUserData();
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
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _stopPolling();
        break;
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username') ?? 'User';
      namaAlat = pref.getString('namaAlat') ?? 'Smart Farm Device';
    });
  }

  void _startPolling() {
    _stopPolling();
    if (_isAppInForeground) {
      _pollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
        if (_isAppInForeground) {
          _loadRealtime();
          _loadKontrol();
          _loadDateTime();
        }
      });
      _loadRealtime();
      _loadKontrol();
      _loadDateTime();
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _loadDateTime() {
    setState(() {
      tanggal = _formatDate(DateTime.now());
      jam = _formatTime(DateTime.now());
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadRealtime() async {
    try {
      var result = await _fetchRealtime();
      _dataRealtimeController.add(result);
    } catch (e) {
      print('Error loading realtime data: $e');
    }
  }

  Future<void> _loadKontrol() async {
    try {
      var result = await _fetchKontrol();
      _dataKontrol.add(result);
    } catch (e) {
      print('Error loading control data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchRealtime({int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    try {
      isDataLoading = true;

      SharedPreferences pref = await SharedPreferences.getInstance();
      String? authToken = pref.getString('authToken');
      String? deviceId = pref.getString('deviceId');

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
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

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

        return {
          'realtimeData': convertedItems,
          'totalItems': jsonData['totalItems'] ?? 0,
          'date': _formatDate(DateTime.now()),
          'time': _formatTime(DateTime.now())
        };
      } else if (response.statusCode == 401) {
        return {'realtimeData': [], 'totalItems': 0, 'error': 'auth_error'};
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (retryCount < maxRetries &&
          (e is SocketException ||
              e is TimeoutException ||
              e is HttpException)) {
        await Future.delayed(retryDelay);
        return _fetchRealtime(retryCount: retryCount + 1);
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

  Future<Map<String, dynamic>> _fetchKontrol({int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    try {
      isDataLoading = true;

      SharedPreferences pref = await SharedPreferences.getInstance();
      String? authToken = pref.getString('authToken');
      String? deviceId = pref.getString('deviceId');

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

        var convertedItems = [];
        for (var item in jsonData['items'] ?? []) {
          convertedItems.add({
            'name': item['namaKontrol'] ?? 'Unknown Control',
            'isON': item['isON'] == true ? 1 : 0,
            'automated': item['automated'] == true ? 1 : 0,
            'parameter': item['parameter'] ?? '',
            'idKontrol': item['idKontrol'] ?? 0,
            'id': item['id']
          });
        }

        return {
          'kontrol': convertedItems,
          'totalItems': jsonData['totalItems'] ?? 0
        };
      } else if (response.statusCode == 401) {
        return {'kontrol': [], 'totalItems': 0, 'error': 'auth_error'};
      } else {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (retryCount < maxRetries &&
          (e is SocketException ||
              e is TimeoutException ||
              e is HttpException)) {
        await Future.delayed(retryDelay);
        return _fetchKontrol(retryCount: retryCount + 1);
      }

      return {'kontrol': [], 'totalItems': 0, 'error': e.toString()};
    } finally {
      isDataLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        physics: ClampingScrollPhysics(),
        children: [
          // Header Section
          _buildHeaderSection(screenWidth),

          // Sensor Grid Section
          _buildSensorGridSection(),

          // Control Section
          _buildControlSection(screenHeight),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(double screenWidth) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.hijau2,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sensor Dashboard",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Real-time monitoring & control",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tanggal,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        jam,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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
    );
  }

  Widget _buildSensorGridSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sensor Readings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder<dynamic>(
            stream: _dataRealtimeController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorWidget();
              } else if (snapshot.hasData) {
                var dataRealtime = snapshot.data['realtimeData'] ?? [];
                return _buildSensorGrid(dataRealtime);
              } else if (snapshot.connectionState != ConnectionState.done) {
                return _buildLoadingGrid();
              } else {
                return _buildNoDataWidget();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(List<dynamic> dataRealtime) {
    if (dataRealtime.isEmpty) {
      return _buildNoDataWidget();
    }

    var jumlahData = dataRealtime.length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: List.generate(jumlahData, (index) {
          var fotoIkon = _getSensorIcon(dataRealtime[index]['name']);

          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: InkWell(
              onTap: () {
                // TODO: Show sensor details
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                  color: AppColor.kuning,
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataRealtime[index]['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColor.hijau1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(fotoIkon),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dataRealtime[index]['value'].toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.hijau1,
                                  ),
                                ),
                                Text(
                                  dataRealtime[index]['unit'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControlSection(double screenHeight) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Device Controls",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder<dynamic>(
            stream: _dataKontrol.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorWidget();
              } else if (snapshot.hasData) {
                var dataKontrol = snapshot.data['kontrol'] ?? [];
                return _buildControlGrid(dataKontrol, screenHeight);
              } else {
                return _buildLoadingWidget();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlGrid(List<dynamic> dataKontrol, double screenHeight) {
    if (dataKontrol.isEmpty) {
      return _buildNoDataWidget();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: dataKontrol.length,
      itemBuilder: (context, index) {
        return _buildControlCard(dataKontrol[index], index, screenHeight);
      },
    );
  }

  Widget _buildControlCard(
      Map<String, dynamic> control, int index, double screenHeight) {
    var status = '';
    var fotoSaklar = '';
    var foto_on = '';
    var foto_off = '';
    var status_foto = '';

    // Set control images based on type
    String controlName = control['name'].toString().toLowerCase();
    if (controlName == 'sprinkler') {
      foto_on = KontrolImages.sprinkler_on;
      foto_off = KontrolImages.sprinkler_off;
    } else if (controlName == 'drip') {
      foto_on = KontrolImages.drip_on;
      foto_off = KontrolImages.drip_off;
    } else if (controlName == 'kipas angin') {
      foto_on = KontrolImages.kipas_on;
      foto_off = KontrolImages.kipas_off;
    } else if (controlName == 'mist') {
      foto_on = KontrolImages.mist_on;
      foto_off = KontrolImages.mist_off;
    } else if (controlName == 'valve') {
      foto_on = KontrolImages.valve_on;
      foto_off = KontrolImages.valve_off;
    } else if (controlName == 'pompa') {
      foto_on = KontrolImages.pompa_on;
      foto_off = KontrolImages.pompa_off;
    } else {
      foto_on = KontrolImages.lainnya_on;
      foto_off = KontrolImages.lainnya_off;
    }

    // Set status and switch image
    if (control['isON'] == 0) {
      status = 'OFF';
      fotoSaklar = 'assets/images/saklar_off.png';
      status_foto = foto_off;
    } else if (control['isON'] == 1) {
      status = 'ON';
      fotoSaklar = 'assets/images/saklar_on.png';
      status_foto = foto_on;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      height: screenHeight * 0.2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Control Image Section
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(status_foto),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        control['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: control['isON'] == 1
                              ? Colors.green.withValues(alpha: 0.8)
                              : Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (control['automated'] == 1)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColor.kuning.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AUTO',
                            style: TextStyle(
                              color: AppColor.hijau1,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Control Switch Section
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(fotoSaklar),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // ON Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (control['automated'] == 0) {
                          _putStatusKontrol(1, index + 1);
                        } else {
                          _showDialogPesan(
                              context, "Kontrol berada di mode Automatis");
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  // OFF Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (control['automated'] == 0) {
                          _putStatusKontrol(0, index + 1);
                        } else {
                          _showDialogPesan(
                              context, "Kontrol berada di mode Automatis");
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Utility Methods
  String _getSensorIcon(String sensorName) {
    String name = sensorName.toLowerCase();
    if (name.contains('suhu udara')) {
      return IconSensor.foto_suhu;
    } else if (name.contains('suhu air')) {
      return IconSensor.foto_suhu_air;
    } else if (name.contains('suhu tanah')) {
      return IconSensor.foto_suhu_tanah;
    } else if (name.contains('ppm air')) {
      return IconSensor.foto_ppm_air;
    } else if (name.contains('ph tanah')) {
      return IconSensor.foto_ph_tanah;
    } else if (name.contains('ph air')) {
      return IconSensor.foto_ph_air;
    } else if (name.contains('kelembapan tanah')) {
      return IconSensor.foto_kelembaban_tanah;
    } else if (name.contains('intensitas cahaya')) {
      return IconSensor.foto_intensitas_cahaya;
    } else if (name.contains('kelembapan udara')) {
      return IconSensor.foto_humidity;
    } else {
      return IconSensor.foto_lainnya;
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColor.red, size: 32),
            SizedBox(height: 8),
            Text(
              'Error loading data',
              style: TextStyle(
                color: AppColor.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: List.generate(4, (index) {
          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijau1),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijau1),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, color: Colors.grey[400], size: 32),
            SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Control Methods
  Future<void> _putStatusKontrol(int status, int index) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? authToken = pref.getString('authToken');
      String? deviceId = pref.getString('deviceId');

      String apiURL = UrlData().url_controls + '/records';

      Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      Map<String, dynamic> body = {
        'deviceId': deviceId,
        'isON': status == 1,
        'controlIndex': index,
      };

      final response = await http.put(
        Uri.parse(apiURL),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Control status updated successfully');
        _loadKontrol(); // Refresh control data
      } else {
        print('Failed to update control status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating control status: $e');
    }
  }

  Future<void> _showDialogPesan(BuildContext context, String pesan) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pesan,
                style: TextStyle(
                  color: AppColor.hijau1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColor.hijau1,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    "Ok",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
