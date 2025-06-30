import 'package:intl/intl.dart';

class Activity {
  final String userId;
  final String activityTypeId;
  final ActivityType activityType;
  final String date; // DD-MM-YYYY format
  final int duration; // in minutes
  final int caloriesBurned;
  final String? intensity; // LOW, MODERATE, HIGH
  final String? notes;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.userId,
    required this.activityTypeId,
    required this.activityType,
    required this.date,
    required this.duration,
    required this.caloriesBurned,
    this.intensity,
    this.notes,
    this.startTime,
    this.endTime,
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

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      userId: json['userId'] ?? '',
      activityTypeId: json['activityTypeId'] ?? '',
      activityType: ActivityType.fromJson(json['activityType'] ?? {}),
      date: json['date'] ?? '',
      duration: json['duration'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      intensity: json['intensity'],
      notes: json['notes'],
      startTime: json['startTime'] != null
          ? _parseDateString(json['startTime'])
          : null,
      endTime:
          json['endTime'] != null ? _parseDateString(json['endTime']) : null,
      createdAt: _parseDateString(json['createdAt']),
      updatedAt: _parseDateString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityTypeId': activityTypeId,
      'activityType': activityType.toJson(),
      'date': date,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'intensity': intensity,
      'notes': notes,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Activity copyWith({
    String? userId,
    String? activityTypeId,
    ActivityType? activityType,
    String? date,
    int? duration,
    int? caloriesBurned,
    String? intensity,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      userId: userId ?? this.userId,
      activityTypeId: activityTypeId ?? this.activityTypeId,
      activityType: activityType ?? this.activityType,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ActivityType {
  final String id;
  final String name;
  final String? description;
  final double metValue;
  final String category; // CARDIO, STRENGTH, FLEXIBILITY, SPORTS, DAILY
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityType({
    required this.id,
    required this.name,
    this.description,
    required this.metValue,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityType.fromJson(Map<String, dynamic> json) {
    return ActivityType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      metValue: (json['metValue'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      createdAt: Activity._parseDateString(json['createdAt']),
      updatedAt: Activity._parseDateString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metValue': metValue,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateActivityRequest {
  final String activityTypeId;
  final String date; // DD-MM-YYYY
  final int duration;
  final int? caloriesBurned;
  final String? intensity;
  final String? notes;

  CreateActivityRequest({
    required this.activityTypeId,
    required this.date,
    required this.duration,
    this.caloriesBurned,
    this.intensity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityTypeId': activityTypeId,
      'date': date,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'intensity': intensity,
      'notes': notes,
    };
  }
}

class DailyActivitySummary {
  final String date;
  final List<Activity> activities;
  final int totalDuration;
  final int totalCaloriesBurned;
  final Map<String, ActivityCategorySummary> byCategory;

  DailyActivitySummary({
    required this.date,
    required this.activities,
    required this.totalDuration,
    required this.totalCaloriesBurned,
    required this.byCategory,
  });

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    return DailyActivitySummary(
      date: json['date'] ?? '',
      activities: (json['activities'] as List? ?? [])
          .map((item) => Activity.fromJson(item))
          .toList(),
      totalDuration: json['totalDuration'] ?? 0,
      totalCaloriesBurned: json['totalCaloriesBurned'] ?? 0,
      byCategory: (json['byCategory'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                key,
                ActivityCategorySummary.fromJson(value),
              )),
    );
  }
}

class ActivityCategorySummary {
  final int duration;
  final int caloriesBurned;

  ActivityCategorySummary({
    required this.duration,
    required this.caloriesBurned,
  });

  factory ActivityCategorySummary.fromJson(Map<String, dynamic> json) {
    return ActivityCategorySummary(
      duration: json['duration'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
    );
  }
}
