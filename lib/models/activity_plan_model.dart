import 'package:intl/intl.dart';
import 'activity_model.dart';

class ActivityPlan {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String startDate; // DD-MM-YYYY format
  final String? endDate; // DD-MM-YYYY format
  final bool isActive;
  final List<PlannedActivity> plannedActivities;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.plannedActivities,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper function to parse DD-MM-YYYY format
  static DateTime _parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    try {
      // Try parsing ISO format first
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // Try parsing DD-MM-YYYY format
        final DateFormat formatter = DateFormat('dd-MM-yyyy');
        return formatter.parse(dateString);
      } catch (e2) {
        try {
          // Try parsing YYYY-MM-DD format
          final DateFormat formatter2 = DateFormat('yyyy-MM-dd');
          return formatter2.parse(dateString);
        } catch (e3) {
          // If all parsing fails, return current time
          return DateTime.now();
        }
      }
    }
  }

  factory ActivityPlan.fromJson(Map<String, dynamic> json) {
    return ActivityPlan(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      isActive: json['isActive'] ?? false,
      plannedActivities: (json['plannedActivities'] as List? ?? [])
          .map((item) => PlannedActivity.fromJson(item))
          .toList(),
      createdAt: _parseDateString(json['createdAt']),
      updatedAt: _parseDateString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'plannedActivities': plannedActivities.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ActivityPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? startDate,
    String? endDate,
    bool? isActive,
    List<PlannedActivity>? plannedActivities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      plannedActivities: plannedActivities ?? this.plannedActivities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PlannedActivity {
  final String activityPlanId;
  final String activityTypeId;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String scheduledTime; // HH:mm format
  final int plannedDuration; // in minutes
  final String? notes;
  final ActivityType activityType;
  final ActivityPlanInfo? activityPlan;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlannedActivity({
    required this.activityPlanId,
    required this.activityTypeId,
    required this.dayOfWeek,
    required this.scheduledTime,
    required this.plannedDuration,
    this.notes,
    required this.activityType,
    this.activityPlan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    return PlannedActivity(
      activityPlanId: json['activityPlanId'] ?? '',
      activityTypeId: json['activityTypeId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      scheduledTime: json['scheduledTime'] ?? '00:00:00',
      plannedDuration: json['plannedDuration'] ?? 0,
      notes: json['notes'],
      activityType: ActivityType.fromJson(json['activityType'] ?? {}),
      activityPlan: json['activityPlan'] != null
          ? ActivityPlanInfo.fromJson(json['activityPlan'])
          : null,
      createdAt: ActivityPlan._parseDateString(json['createdAt']),
      updatedAt: ActivityPlan._parseDateString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityPlanId': activityPlanId,
      'activityTypeId': activityTypeId,
      'dayOfWeek': dayOfWeek,
      'scheduledTime': scheduledTime,
      'plannedDuration': plannedDuration,
      'notes': notes,
      'activityType': activityType.toJson(),
      'activityPlan': activityPlan?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ActivityPlanInfo {
  final String id;
  final String name;

  ActivityPlanInfo({
    required this.id,
    required this.name,
  });

  factory ActivityPlanInfo.fromJson(Map<String, dynamic> json) {
    return ActivityPlanInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ScheduledActivity extends PlannedActivity {
  final String planName;
  final String planId;

  ScheduledActivity({
    required super.activityPlanId,
    required super.activityTypeId,
    required super.dayOfWeek,
    required super.scheduledTime,
    required super.plannedDuration,
    super.notes,
    required super.activityType,
    super.activityPlan,
    required super.createdAt,
    required super.updatedAt,
    required this.planName,
    required this.planId,
  });

  factory ScheduledActivity.fromJson(Map<String, dynamic> json) {
    return ScheduledActivity(
      activityPlanId: json['activityPlanId'] ?? '',
      activityTypeId: json['activityTypeId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      scheduledTime: json['scheduledTime'] ?? '00:00:00',
      plannedDuration: json['plannedDuration'] ?? 0,
      notes: json['notes'],
      activityType: ActivityType.fromJson(json['activityType'] ?? {}),
      activityPlan: json['activityPlan'] != null
          ? ActivityPlanInfo.fromJson(json['activityPlan'])
          : null,
      createdAt: ActivityPlan._parseDateString(json['createdAt']),
      updatedAt: ActivityPlan._parseDateString(json['updatedAt']),
      planName: json['planName'] ?? '',
      planId: json['planId'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'planName': planName,
      'planId': planId,
    });
    return json;
  }
}

class WeeklySchedule {
  final Map<int, List<ScheduledActivity>> weeklySchedule;
  final int totalActivePlans;
  final int totalPlannedActivities;

  WeeklySchedule({
    required this.weeklySchedule,
    required this.totalActivePlans,
    required this.totalPlannedActivities,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final scheduleJson = json['weeklySchedule'] as Map<String, dynamic>? ?? {};
    final weeklySchedule = <int, List<ScheduledActivity>>{};

    for (final entry in scheduleJson.entries) {
      final dayIndex = int.tryParse(entry.key) ?? 0;
      final activities = (entry.value as List? ?? [])
          .map((item) => ScheduledActivity.fromJson(item))
          .toList();
      weeklySchedule[dayIndex] = activities;
    }

    return WeeklySchedule(
      weeklySchedule: weeklySchedule,
      totalActivePlans: json['totalActivePlans'] ?? 0,
      totalPlannedActivities: json['totalPlannedActivities'] ?? 0,
    );
  }
}

class CreateActivityPlanRequest {
  final String name;
  final String? description;
  final String startDate; // DD-MM-YYYY
  final String? endDate; // DD-MM-YYYY

  CreateActivityPlanRequest({
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class CreatePlannedActivityRequest {
  final String activityTypeId;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String scheduledTime; // HH:mm
  final int plannedDuration; // in minutes
  final String? notes;

  CreatePlannedActivityRequest({
    required this.activityTypeId,
    required this.dayOfWeek,
    required this.scheduledTime,
    required this.plannedDuration,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityTypeId': activityTypeId,
      'dayOfWeek': dayOfWeek,
      'scheduledTime': scheduledTime,
      'plannedDuration': plannedDuration,
      'notes': notes,
    };
  }
}
