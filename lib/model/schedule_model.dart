// ignore_for_file: prefer_const_constructors

class ScheduleModel {
  final String id;
  final String name;
  final String description;
  final String deviceId;
  final String controlId;
  final ScheduleType type;
  final DateTime startTime;
  final DateTime? endTime;
  final List<int> daysOfWeek; // 0=Sunday, 1=Monday, etc.
  final bool isActive;
  final bool isRepeating;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.deviceId,
    required this.controlId,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.daysOfWeek,
    required this.isActive,
    required this.isRepeating,
    required this.parameters,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      deviceId: json['deviceId'] ?? '',
      controlId: json['controlId'] ?? '',
      type: _parseScheduleType(json['type']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      isActive: json['isActive'] ?? false,
      isRepeating: json['isRepeating'] ?? false,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      createdAt: DateTime.parse(json['created'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated'] ??
          json['updatedAt'] ??
          DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'deviceId': deviceId,
      'controlId': controlId,
      'type': _scheduleTypeToString(type),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
      'isRepeating': isRepeating,
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ScheduleType _parseScheduleType(dynamic value) {
    switch (value) {
      case 'time_based':
        return ScheduleType.timeBased;
      case 'sensor_based':
        return ScheduleType.sensorBased;
      case 'manual':
        return ScheduleType.manual;
      default:
        return ScheduleType.manual;
    }
  }

  static String _scheduleTypeToString(ScheduleType type) {
    switch (type) {
      case ScheduleType.timeBased:
        return 'time_based';
      case ScheduleType.sensorBased:
        return 'sensor_based';
      case ScheduleType.manual:
        return 'manual';
    }
  }

  ScheduleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? deviceId,
    String? controlId,
    ScheduleType? type,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? daysOfWeek,
    bool? isActive,
    bool? isRepeating,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deviceId: deviceId ?? this.deviceId,
      controlId: controlId ?? this.controlId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      isRepeating: isRepeating ?? this.isRepeating,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    if (endTime == null) return '';
    return '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  String get daysOfWeekString {
    if (daysOfWeek.isEmpty) return 'Never';
    if (daysOfWeek.length == 7) return 'Every day';

    List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return daysOfWeek.map((day) => dayNames[day]).join(', ');
  }

  bool get isScheduledForToday {
    int today = DateTime.now().weekday % 7; // Convert to 0=Sunday format
    return daysOfWeek.contains(today);
  }
}

enum ScheduleType {
  timeBased,
  sensorBased,
  manual,
}

class AutomationRule {
  final String id;
  final String name;
  final String description;
  final String deviceId;
  final String controlId;
  final List<AutomationCondition> conditions;
  final List<AutomationAction> actions;
  final bool isActive;
  final AutomationLogic logic; // AND or OR for multiple conditions
  final DateTime createdAt;
  final DateTime updatedAt;

  AutomationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.deviceId,
    required this.controlId,
    required this.conditions,
    required this.actions,
    required this.isActive,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      deviceId: json['deviceId'] ?? '',
      controlId: json['controlId'] ?? '',
      conditions: (json['conditions'] as List?)
              ?.map((e) => AutomationCondition.fromJson(e))
              .toList() ??
          [],
      actions: (json['actions'] as List?)
              ?.map((e) => AutomationAction.fromJson(e))
              .toList() ??
          [],
      isActive: json['isActive'] ?? false,
      logic: _parseAutomationLogic(json['logic']),
      createdAt: DateTime.parse(json['created'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated'] ??
          json['updatedAt'] ??
          DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'deviceId': deviceId,
      'controlId': controlId,
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'actions': actions.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'logic': _automationLogicToString(logic),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static AutomationLogic _parseAutomationLogic(dynamic value) {
    switch (value) {
      case 'AND':
      case 'and':
        return AutomationLogic.and;
      case 'OR':
      case 'or':
        return AutomationLogic.or;
      default:
        return AutomationLogic.and;
    }
  }

  static String _automationLogicToString(AutomationLogic logic) {
    switch (logic) {
      case AutomationLogic.and:
        return 'AND';
      case AutomationLogic.or:
        return 'OR';
    }
  }

  AutomationRule copyWith({
    String? id,
    String? name,
    String? description,
    String? deviceId,
    String? controlId,
    List<AutomationCondition>? conditions,
    List<AutomationAction>? actions,
    bool? isActive,
    AutomationLogic? logic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deviceId: deviceId ?? this.deviceId,
      controlId: controlId ?? this.controlId,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      isActive: isActive ?? this.isActive,
      logic: logic ?? this.logic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AutomationCondition {
  final String sensorType;
  final ComparisonOperator operator;
  final double value;
  final String unit;

  AutomationCondition({
    required this.sensorType,
    required this.operator,
    required this.value,
    required this.unit,
  });

  factory AutomationCondition.fromJson(Map<String, dynamic> json) {
    return AutomationCondition(
      sensorType: json['sensor'] ?? json['sensorType'] ?? '',
      operator: _parseComparisonOperator(json['operator']),
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensor': sensorType,
      'operator': _comparisonOperatorToString(operator),
      'value': value,
      'unit': unit,
    };
  }

  static ComparisonOperator _parseComparisonOperator(dynamic value) {
    switch (value) {
      case '>':
      case 'gt':
        return ComparisonOperator.greaterThan;
      case '<':
      case 'lt':
        return ComparisonOperator.lessThan;
      case '=':
      case '==':
      case 'eq':
        return ComparisonOperator.equalTo;
      case '>=':
      case 'gte':
        return ComparisonOperator.greaterThanOrEqual;
      case '<=':
      case 'lte':
        return ComparisonOperator.lessThanOrEqual;
      default:
        return ComparisonOperator.equalTo;
    }
  }

  static String _comparisonOperatorToString(ComparisonOperator operator) {
    switch (operator) {
      case ComparisonOperator.greaterThan:
        return '>';
      case ComparisonOperator.lessThan:
        return '<';
      case ComparisonOperator.equalTo:
        return '=';
      case ComparisonOperator.greaterThanOrEqual:
        return '>=';
      case ComparisonOperator.lessThanOrEqual:
        return '<=';
    }
  }

  String get description {
    String operatorText = '';
    switch (operator) {
      case ComparisonOperator.greaterThan:
        operatorText = '>';
        break;
      case ComparisonOperator.lessThan:
        operatorText = '<';
        break;
      case ComparisonOperator.equalTo:
        operatorText = '=';
        break;
      case ComparisonOperator.greaterThanOrEqual:
        operatorText = '>=';
        break;
      case ComparisonOperator.lessThanOrEqual:
        operatorText = '<=';
        break;
    }
    return '$sensorType $operatorText $value $unit';
  }

  bool evaluate(double currentValue) {
    switch (operator) {
      case ComparisonOperator.greaterThan:
        return currentValue > value;
      case ComparisonOperator.lessThan:
        return currentValue < value;
      case ComparisonOperator.equalTo:
        return currentValue == value;
      case ComparisonOperator.greaterThanOrEqual:
        return currentValue >= value;
      case ComparisonOperator.lessThanOrEqual:
        return currentValue <= value;
    }
  }
}

class AutomationAction {
  final String controlId;
  final ActionType actionType;
  final Map<String, dynamic> parameters;

  AutomationAction({
    required this.controlId,
    required this.actionType,
    required this.parameters,
  });

  factory AutomationAction.fromJson(Map<String, dynamic> json) {
    return AutomationAction(
      controlId: json['controlId'] ?? '',
      actionType: _parseActionType(json['type'] ?? json['actionType']),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'controlId': controlId,
      'type': _actionTypeToString(actionType),
      'parameters': parameters,
    };
  }

  static ActionType _parseActionType(dynamic value) {
    switch (value) {
      case 'turn_on':
        return ActionType.turnOn;
      case 'turn_off':
        return ActionType.turnOff;
      case 'set_value':
        return ActionType.setValue;
      case 'toggle':
        return ActionType.toggle;
      default:
        return ActionType.turnOn;
    }
  }

  static String _actionTypeToString(ActionType type) {
    switch (type) {
      case ActionType.turnOn:
        return 'turn_on';
      case ActionType.turnOff:
        return 'turn_off';
      case ActionType.setValue:
        return 'set_value';
      case ActionType.toggle:
        return 'toggle';
    }
  }

  String get description {
    switch (actionType) {
      case ActionType.turnOn:
        return 'Turn ON';
      case ActionType.turnOff:
        return 'Turn OFF';
      case ActionType.setValue:
        return 'Set to ${parameters['value']}';
      case ActionType.toggle:
        return 'Toggle';
    }
  }
}

enum AutomationLogic {
  and,
  or,
}

enum ComparisonOperator {
  greaterThan,
  lessThan,
  equalTo,
  greaterThanOrEqual,
  lessThanOrEqual,
}

enum ActionType {
  turnOn,
  turnOff,
  setValue,
  toggle,
}

class ScheduleExecution {
  final String id;
  final String scheduleId;
  final DateTime executedAt;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic> result;

  ScheduleExecution({
    required this.id,
    required this.scheduleId,
    required this.executedAt,
    required this.success,
    this.errorMessage,
    required this.result,
  });

  factory ScheduleExecution.fromJson(Map<String, dynamic> json) {
    return ScheduleExecution(
      id: json['id'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      executedAt: DateTime.parse(json['executedAt']),
      success: json['status'] == 'success',
      errorMessage: json['error'],
      result: Map<String, dynamic>.from(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'executedAt': executedAt.toIso8601String(),
      'status': success ? 'success' : 'failed',
      'error': errorMessage,
      'result': result,
    };
  }
}
