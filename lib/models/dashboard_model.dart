class DashboardData {
  final UserDashboardInfo user;
  final CaloriesInfo calories;
  final ActivitiesInfo activities;
  final WeightGoal? weightGoal;
  final BMIRecord? latestBMI;
  final String date;
  final List<CaloriesTrackerEntry> caloriesTracker;

  DashboardData({
    required this.user,
    required this.calories,
    required this.activities,
    this.weightGoal,
    this.latestBMI,
    required this.date,
    required this.caloriesTracker,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: UserDashboardInfo.fromJson(json['user']),
      calories: CaloriesInfo.fromJson(json['calories']),
      activities: ActivitiesInfo.fromJson(json['activities']),
      weightGoal: json['weightGoal'] != null
          ? WeightGoal.fromJson(json['weightGoal'])
          : null,
      latestBMI: json['latestBMI'] != null
          ? BMIRecord.fromJson(json['latestBMI'])
          : null,
      date: json['date'] as String,
      caloriesTracker: json['caloriesTracker'] != null
          ? List<CaloriesTrackerEntry>.from(json['caloriesTracker']
              .map((x) => CaloriesTrackerEntry.fromJson(x)))
          : [],
    );
  }
}

class UserDashboardInfo {
  final String name;
  final double? weight;
  final double? height;
  final double? bmr;
  final double? tdee;

  UserDashboardInfo({
    required this.name,
    this.weight,
    this.height,
    this.bmr,
    this.tdee,
  });

  factory UserDashboardInfo.fromJson(Map<String, dynamic> json) {
    return UserDashboardInfo(
      name: json['name'] as String,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
      tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
    );
  }
}

class CaloriesInfo {
  final double consumed;
  final double burnedFromActivities;
  final double bmr;
  final double tdee;
  final double net;
  final double target;

  CaloriesInfo({
    required this.consumed,
    required this.burnedFromActivities,
    required this.bmr,
    required this.tdee,
    required this.net,
    required this.target,
  });

  factory CaloriesInfo.fromJson(Map<String, dynamic> json) {
    return CaloriesInfo(
      consumed: (json['consumed'] as num).toDouble(),
      burnedFromActivities: (json['burnedFromActivities'] as num).toDouble(),
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
    );
  }
}

class ActivitiesInfo {
  final int count;
  final int totalDuration;
  final double totalCaloriesBurned;

  ActivitiesInfo({
    required this.count,
    required this.totalDuration,
    required this.totalCaloriesBurned,
  });

  factory ActivitiesInfo.fromJson(Map<String, dynamic> json) {
    return ActivitiesInfo(
      count: json['count'] as int,
      totalDuration: json['totalDuration'] as int,
      totalCaloriesBurned: (json['totalCaloriesBurned'] as num).toDouble(),
    );
  }
}

class WeightGoal {
  final String? id;
  final String? userId;
  final double? startWeight;
  final double? targetWeight;
  final String? startDate;
  final String? targetDate;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  WeightGoal({
    this.id,
    this.userId,
    this.startWeight,
    this.targetWeight,
    this.startDate,
    this.targetDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory WeightGoal.fromJson(Map<String, dynamic> json) {
    return WeightGoal(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      startWeight: json['startWeight'] != null
          ? (json['startWeight'] as num).toDouble()
          : null,
      targetWeight: json['targetWeight'] != null
          ? (json['targetWeight'] as num).toDouble()
          : null,
      startDate: json['startDate'] as String?,
      targetDate: json['targetDate'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class BMIRecord {
  final String? id;
  final String? userId;
  final double? bmi;
  final double? weight;
  final double? height;
  final String? status;
  final String? recordedAt;
  final String? createdAt;
  final String? updatedAt;
  final NutritionSummary? nutritionSummary;

  BMIRecord({
    this.id,
    this.userId,
    this.bmi,
    this.weight,
    this.height,
    this.status,
    this.recordedAt,
    this.createdAt,
    this.updatedAt,
    this.nutritionSummary,
  });

  factory BMIRecord.fromJson(Map<String, dynamic> json) {
    return BMIRecord(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      status: json['status'] as String?,
      recordedAt: json['recordedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      nutritionSummary: json['nutritionSummary'] != null
          ? NutritionSummary.fromJson(json['nutritionSummary'])
          : null,
    );
  }
}

class CaloriesTrackerEntry {
  final String label;
  final String? date;
  final String? start;
  final String? end;
  final double calories;

  CaloriesTrackerEntry({
    required this.label,
    this.date,
    this.start,
    this.end,
    required this.calories,
  });

  factory CaloriesTrackerEntry.fromJson(Map<String, dynamic> json) {
    return CaloriesTrackerEntry(
      label: json['label'] as String,
      date: json['date'] as String?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      calories: (json['calories'] as num).toDouble(),
    );
  }
}

class NutritionSummary {
  final NutrientInfo fat;
  final NutrientInfo protein;
  final CalorieInfo calories;
  final NutrientInfo carbohydrate;

  NutritionSummary({
    required this.fat,
    required this.protein,
    required this.calories,
    required this.carbohydrate,
  });

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    return NutritionSummary(
      fat: NutrientInfo.fromJson(json['fat']),
      protein: NutrientInfo.fromJson(json['protein']),
      calories: CalorieInfo.fromJson(json['calories']),
      carbohydrate: NutrientInfo.fromJson(json['carbohydrate']),
    );
  }
}

class NutrientInfo {
  final int max;
  final int min;
  final String unit;

  NutrientInfo({
    required this.max,
    required this.min,
    required this.unit,
  });

  factory NutrientInfo.fromJson(Map<String, dynamic> json) {
    return NutrientInfo(
      max: json['max'] as int,
      min: json['min'] as int,
      unit: json['unit'] as String,
    );
  }
}

class CalorieInfo {
  final int max;
  final int min;

  CalorieInfo({
    required this.max,
    required this.min,
  });

  factory CalorieInfo.fromJson(Map<String, dynamic> json) {
    return CalorieInfo(
      max: json['max'] as int,
      min: json['min'] as int,
    );
  }
}
