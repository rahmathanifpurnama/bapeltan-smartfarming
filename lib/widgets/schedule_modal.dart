// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/model/schedule_model.dart';
import 'package:smartfarming_bapeltan/api/schedule_api.dart';

class ScheduleModal extends StatefulWidget {
  final String? preSelectedControlId;
  final Function(ScheduleModel)? onScheduleCreated;

  const ScheduleModal({
    Key? key,
    this.preSelectedControlId,
    this.onScheduleCreated,
  }) : super(key: key);

  @override
  State<ScheduleModal> createState() => _ScheduleModalState();
}

class _ScheduleModalState extends State<ScheduleModal> {
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
  bool _isSaving = false;

  final List<Map<String, dynamic>> _availableControls = [
    {'id': 'sprinkler', 'name': 'Sprinkler System', 'icon': Icons.water_drop},
    {'id': 'drip', 'name': 'Drip Irrigation', 'icon': Icons.opacity},
    {'id': 'kipas angin', 'name': 'Kipas Angin', 'icon': Icons.air},
    {'id': 'mist', 'name': 'Mist System', 'icon': Icons.cloud},
    {'id': 'valve', 'name': 'Water Valve', 'icon': Icons.tune},
    {
      'id': 'pompa',
      'name': 'Water Pump',
      'icon': Icons.settings_input_component
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedControlId = widget.preSelectedControlId ?? '';
    if (_selectedControlId.isEmpty && _availableControls.isNotEmpty) {
      _selectedControlId = _availableControls.first['id'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      SizedBox(height: 20),
                      _buildControlSelectionSection(),
                      SizedBox(height: 20),
                      _buildScheduleTypeSection(),
                      SizedBox(height: 20),
                      _buildTimeSettingsSection(),
                      SizedBox(height: 20),
                      _buildDaysSelectionSection(),
                      SizedBox(height: 20),
                      _buildSettingsSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.hijau1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quick Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Schedule Name',
            hintText: 'e.g., Morning Watering',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColor.hijau1),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter schedule name';
            }
            return null;
          },
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Brief description of this schedule',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColor.hijau1),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildControlSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Control Device',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedControlId,
              isExpanded: true,
              items: _availableControls.map((control) {
                return DropdownMenuItem<String>(
                  value: control['id'],
                  child: Row(
                    children: [
                      Icon(control['icon'], color: AppColor.hijau1, size: 20),
                      SizedBox(width: 12),
                      Text(control['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedControlId = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 8),
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
    );
  }

  Widget _buildTimeSettingsSection() {
    if (_selectedType != ScheduleType.timeBased) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
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
    );
  }

  Widget _buildDaysSelectionSection() {
    if (_selectedType != ScheduleType.timeBased || !_isRepeating) {
      return SizedBox.shrink();
    }

    List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat Days',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 12),
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
              selectedColor: AppColor.hijau1.withOpacity(0.3),
              checkmarkColor: AppColor.hijau1,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.hijau1,
          ),
        ),
        SizedBox(height: 8),
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
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColor.hijau1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColor.hijau1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.hijau1,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Create Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
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

      // Get deviceId from SharedPreferences
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? deviceId = pref.getString('deviceId') ?? '016j4islabono91';

      ScheduleModel schedule = ScheduleModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        deviceId: deviceId,
        controlId: _selectedControlId,
        type: _selectedType,
        startTime: startDateTime,
        endTime: endDateTime,
        daysOfWeek: _selectedType == ScheduleType.timeBased && _isRepeating
            ? _selectedDays
            : [],
        isActive: _isActive,
        isRepeating: _isRepeating,
        parameters: {},
        createdAt: now,
        updatedAt: now,
      );

      ScheduleApi api = ScheduleApi();
      ScheduleModel? result = await api.createSchedule(schedule);

      if (result != null) {
        _showSnackBar('Schedule created successfully!');
        if (widget.onScheduleCreated != null) {
          widget.onScheduleCreated!(result);
        }
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar('Failed to create schedule. Please try again.');
      }
    } catch (e) {
      print('Error creating schedule: $e');
      _showSnackBar('Error creating schedule: ${e.toString()}');
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
        duration: Duration(seconds: 3),
      ),
    );
  }
}
