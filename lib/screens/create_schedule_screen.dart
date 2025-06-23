// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/model/schedule_model.dart';
import 'package:smartfarming_bapeltan/api/schedule_api.dart';

class CreateScheduleScreen extends StatefulWidget {
  final ScheduleModel? existingSchedule;

  const CreateScheduleScreen({Key? key, this.existingSchedule})
      : super(key: key);

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  ScheduleType _selectedType = ScheduleType.timeBased;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  List<int> _selectedDays = [];
  bool _isRepeating = true;
  bool _isActive = true;
  String _selectedControlId = '';
  Map<String, dynamic> _parameters = {};

  bool _isSaving = false;
  List<String> _availableControls = [
    'sprinkler',
    'drip',
    'kipas angin',
    'mist',
    'valve',
    'pompa',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _loadExistingSchedule();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadExistingSchedule() {
    final schedule = widget.existingSchedule!;
    _nameController.text = schedule.name;
    _descriptionController.text = schedule.description;
    _selectedType = schedule.type;
    _startTime = TimeOfDay.fromDateTime(schedule.startTime);
    _endTime = schedule.endTime != null
        ? TimeOfDay.fromDateTime(schedule.endTime!)
        : null;
    _selectedDays = List.from(schedule.daysOfWeek);
    _isRepeating = schedule.isRepeating;
    _isActive = schedule.isActive;
    _selectedControlId = schedule.controlId;
    _parameters = Map.from(schedule.parameters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColor.hijau2,
        elevation: 0,
        title: Text(
          widget.existingSchedule != null ? 'Edit Schedule' : 'Create Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSchedule,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Basic Information
              _buildBasicInfoSection(),

              SizedBox(height: 20),

              // Schedule Type
              _buildScheduleTypeSection(),

              SizedBox(height: 20),

              // Time Settings
              _buildTimeSettingsSection(),

              SizedBox(height: 20),

              // Days Selection
              _buildDaysSelectionSection(),

              SizedBox(height: 20),

              // Control Selection
              _buildControlSelectionSection(),

              SizedBox(height: 20),

              // Settings
              _buildSettingsSection(),

              SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),

          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Schedule Name',
              prefixIcon: Icon(Icons.schedule, color: AppColor.hijau1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.hijau1, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a schedule name';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              prefixIcon: Icon(Icons.description, color: AppColor.hijau1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.hijau1, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTypeSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
            'Schedule Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),

          // Time Based
          RadioListTile<ScheduleType>(
            title: Text('Time Based'),
            subtitle: Text('Run at specific times'),
            value: ScheduleType.timeBased,
            groupValue: _selectedType,
            activeColor: AppColor.hijau1,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),

          // Sensor Based
          RadioListTile<ScheduleType>(
            title: Text('Sensor Based'),
            subtitle: Text('Run based on sensor readings'),
            value: ScheduleType.sensorBased,
            groupValue: _selectedType,
            activeColor: AppColor.hijau1,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),

          // Manual
          RadioListTile<ScheduleType>(
            title: Text('Manual'),
            subtitle: Text('Run manually only'),
            value: ScheduleType.manual,
            groupValue: _selectedType,
            activeColor: AppColor.hijau1,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsSection() {
    if (_selectedType != ScheduleType.timeBased) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
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
            'Time Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),

          // Start Time
          ListTile(
            leading: Icon(Icons.access_time, color: AppColor.hijau1),
            title: Text('Start Time'),
            subtitle: Text(_startTime.format(context)),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),

          Divider(),

          // End Time (Optional)
          ListTile(
            leading: Icon(Icons.access_time_filled, color: AppColor.hijau1),
            title: Text('End Time (Optional)'),
            subtitle: Text(_endTime?.format(context) ?? 'Not set'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endTime != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _endTime = null;
                      });
                    },
                  ),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime ?? _startTime,
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelectionSection() {
    if (_selectedType != ScheduleType.timeBased || !_isRepeating) {
      return SizedBox.shrink();
    }

    List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: EdgeInsets.all(20),
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
            'Repeat Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              bool isSelected = _selectedDays.contains(index);
              return FilterChip(
                label: Text(dayNames[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(index);
                    } else {
                      _selectedDays.remove(index);
                    }
                  });
                },
                selectedColor: AppColor.hijau3,
                checkmarkColor: AppColor.hijau1,
                labelStyle: TextStyle(
                  color: isSelected ? AppColor.hijau1 : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDays = List.generate(7, (index) => index);
                  });
                },
                child: Text(
                  'Select All',
                  style: TextStyle(color: AppColor.hijau1),
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDays.clear();
                  });
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlSelectionSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
            'Control Device',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedControlId.isEmpty ? null : _selectedControlId,
            decoration: InputDecoration(
              labelText: 'Select Control Device',
              prefixIcon: Icon(Icons.settings_remote, color: AppColor.hijau1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.hijau1, width: 2),
              ),
            ),
            items: _availableControls.map((control) {
              return DropdownMenuItem<String>(
                value: control,
                child: Text(control),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedControlId = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a control device';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.hijau1,
            ),
          ),
          SizedBox(height: 16),

          // Repeating Switch
          if (_selectedType == ScheduleType.timeBased)
            SwitchListTile(
              title: Text('Repeating Schedule'),
              subtitle: Text('Run this schedule repeatedly'),
              value: _isRepeating,
              activeColor: AppColor.hijau1,
              onChanged: (value) {
                setState(() {
                  _isRepeating = value;
                  if (!value) {
                    _selectedDays.clear();
                  }
                });
              },
            ),

          // Active Switch
          SwitchListTile(
            title: Text('Active'),
            subtitle: Text('Enable this schedule'),
            value: _isActive,
            activeColor: AppColor.hijau1,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.hijau1,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                widget.existingSchedule != null
                    ? 'Update Schedule'
                    : 'Create Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == ScheduleType.timeBased &&
        _isRepeating &&
        _selectedDays.isEmpty) {
      _showSnackBar('Please select at least one day for repeating schedule');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      DateTime now = DateTime.now();
      DateTime startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endTime != null) {
        endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      ScheduleModel schedule = ScheduleModel(
        id: widget.existingSchedule?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        deviceId: 'device_123', // This would come from SharedPreferences
        controlId: _selectedControlId,
        type: _selectedType,
        startTime: startDateTime,
        endTime: endDateTime,
        daysOfWeek: _selectedType == ScheduleType.timeBased && _isRepeating
            ? _selectedDays
            : [],
        isActive: _isActive,
        isRepeating: _isRepeating,
        parameters: _parameters,
        createdAt: widget.existingSchedule?.createdAt ?? now,
        updatedAt: now,
      );

      ScheduleApi api = ScheduleApi();
      ScheduleModel? result;

      if (widget.existingSchedule != null) {
        result = await api.updateSchedule(schedule);
      } else {
        result = await api.createSchedule(schedule);
      }

      if (result != null) {
        _showSnackBar(widget.existingSchedule != null
            ? 'Schedule updated successfully!'
            : 'Schedule created successfully!');

        await Future.delayed(Duration(seconds: 1));
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar('Failed to save schedule. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error saving schedule: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.hijau1,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
