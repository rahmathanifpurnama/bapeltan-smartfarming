// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/common/url.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late StreamController _dataRealtimeController;
  Timer? _pollingTimer;
  bool _isAppInForeground = true;

  String username = '';
  String namaAlat = '';
  var tanggal = '';
  var jam = '';
  bool isDataLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dataRealtimeController = StreamController();
    _loadUserData();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _dataRealtimeController.close();
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
          _loadDateTime();
        }
      });
      _loadRealtime();
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        physics: ClampingScrollPhysics(),
        children: [
          // User Greeting Section
          _buildGreetingSection(screenWidth),

          // Sensor Statistics Section
          _buildSensorStatisticsSection(),

          // Quick Actions Section
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(double screenWidth) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.hijau2,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $username! 👋",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Welcome to your Smart Farm",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Today: $tanggal at $jam",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.wb_sunny,
                    color: Colors.orange[300],
                    size: 32,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.kuning.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                namaAlat,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.hijau1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatisticsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sensor Statistics",
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
                return _buildErrorCard();
              } else if (snapshot.hasData) {
                var dataRealtime = snapshot.data['realtimeData'] ?? [];
                return _buildSensorCharts(dataRealtime);
              } else {
                return _buildLoadingCard();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCharts(List<dynamic> sensorData) {
    if (sensorData.isEmpty) {
      return _buildNoDataCard();
    }

    return Column(
      children: [
        // Sensor Overview Cards
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sensorData.length > 4 ? 4 : sensorData.length,
            itemBuilder: (context, index) {
              var sensor = sensorData[index];
              return _buildSensorOverviewCard(sensor);
            },
          ),
        ),
        SizedBox(height: 20),

        // Chart Section
        Container(
          height: 250,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sensor Trends",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.hijau1,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: _buildLineChart(sensorData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorOverviewCard(Map<String, dynamic> sensor) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getSensorIcon(sensor['name']),
            color: AppColor.hijau1,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            sensor['name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${sensor['value'] ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.hijau1,
                ),
              ),
              SizedBox(width: 4),
              Text(
                sensor['unit'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> sensorData) {
    List<FlSpot> spots = [];

    for (int i = 0; i < sensorData.length && i < 7; i++) {
      double value = double.tryParse(sensorData[i]['value'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt()}h', style: style),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                return Text('${value.toInt()}', style: style);
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: spots.isNotEmpty
            ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2
            : 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppColor.hijau1,
                AppColor.hijau2,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColor.hijau1,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColor.hijau1.withValues(alpha: 0.3),
                  AppColor.hijau2.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              'Error loading sensor data',
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

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              'Loading sensor data...',
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

  Widget _buildNoDataCard() {
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
              'No sensor data available',
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

  Widget _buildQuickActionsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.dashboard,
                  title: 'Sensor Dashboard',
                  subtitle: 'Monitor all sensors',
                  onTap: () {
                    // TODO: Navigate to sensor dashboard
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.schedule,
                  title: 'Scheduling',
                  subtitle: 'Manage automation',
                  onTap: () {
                    // TODO: Navigate to scheduling
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Configure system',
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'View reports',
                  onTap: () {
                    // TODO: Navigate to analytics
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.hijau3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColor.hijau1,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColor.hijau1,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSensorIcon(String sensorName) {
    String name = sensorName.toLowerCase();
    if (name.contains('suhu') || name.contains('temperature')) {
      return Icons.thermostat;
    } else if (name.contains('kelembapan') || name.contains('humidity')) {
      return Icons.water_drop;
    } else if (name.contains('ph')) {
      return Icons.science;
    } else if (name.contains('ppm')) {
      return Icons.opacity;
    } else if (name.contains('cahaya') || name.contains('light')) {
      return Icons.wb_sunny;
    } else {
      return Icons.sensors;
    }
  }
}
