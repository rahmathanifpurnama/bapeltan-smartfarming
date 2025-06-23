// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/model/schedule_model.dart';
import 'package:smartfarming_bapeltan/api/schedule_api.dart';
import 'package:smartfarming_bapeltan/screens/create_schedule_screen.dart';
import 'package:smartfarming_bapeltan/widgets/schedule_modal.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({Key? key}) : super(key: key);

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  List<ScheduleModel> _schedules = [];
  List<AutomationRule> _automationRules = [];
  bool _isLoading = true;
  final ScheduleApi _scheduleApi = ScheduleApi();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schedules = await _scheduleApi.getSchedules();
      final rules = await _scheduleApi.getAutomationRules();

      setState(() {
        _schedules = schedules;
        _automationRules = rules;
      });
    } catch (e) {
      print('Error loading schedules: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header Section
          _buildHeaderSection(),

          SizedBox(height: 24),

          // Quick Schedule Section
          _buildQuickScheduleSection(),

          SizedBox(height: 24),

          // Active Schedules Section
          _buildActiveSchedulesSection(),

          SizedBox(height: 24),

          // Automation Rules Section
          _buildAutomationRulesSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.hijau2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Scheduling & Automation",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Manage your smart farming schedules and automation rules",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickScheduleCard(
                icon: Icons.water_drop,
                title: "Watering",
                subtitle: "Schedule irrigation",
                onTap: () {
                  _showQuickScheduleModal('sprinkler');
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildQuickScheduleCard(
                icon: Icons.air,
                title: "Ventilation",
                subtitle: "Schedule fans",
                onTap: () {
                  _showQuickScheduleModal('kipas angin');
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickScheduleCard(
                icon: Icons.wb_sunny,
                title: "Lighting",
                subtitle: "Schedule lights",
                onTap: () {
                  _showQuickScheduleModal('valve');
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildQuickScheduleCard(
                icon: Icons.thermostat,
                title: "Climate",
                subtitle: "Temperature control",
                onTap: () {
                  _showQuickScheduleModal('mist');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickScheduleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: 8),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Schedules",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.hijau1,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all schedules
              },
              child: Text(
                "View All",
                style: TextStyle(
                  color: AppColor.hijau1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_isLoading)
          _buildLoadingSchedules()
        else if (_schedules.isEmpty)
          _buildNoSchedules()
        else
          ..._schedules
              .take(3)
              .map((schedule) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: _buildScheduleCard(schedule),
                  ))
              .toList(),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: schedule.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.hijau1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  schedule.controlId,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                schedule.formattedStartTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColor.hijau1,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: schedule.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 12,
                    color: schedule.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Automation Rules",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColor.hijau1,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                "Smart Automation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.hijau1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Set up intelligent automation rules based on sensor readings and environmental conditions.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to automation setup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.hijau1,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Create Automation Rule",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Navigation and Helper Methods
  Future<void> _showQuickScheduleModal(String controlType) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ScheduleModal(
        preSelectedControlId: controlType,
        onScheduleCreated: (schedule) {
          // Refresh schedules list
          _loadSchedules();
        },
      ),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  Future<void> _navigateToCreateSchedule(String controlType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateScheduleScreen(),
      ),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  Widget _buildLoadingSchedules() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              'Loading schedules...',
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

  Widget _buildNoSchedules() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            Icon(Icons.schedule_outlined, color: Colors.grey[400], size: 32),
            SizedBox(height: 8),
            Text(
              'No schedules yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Create your first schedule above',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
