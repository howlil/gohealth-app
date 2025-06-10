class DashboardData {
  final UserDashboardInfo user;
  final CaloriesInfo calories;
  final ActivitiesInfo activities;
  final WeightGoal? weightGoal;
  final BMIRecord? latestBMI;
  final String date;

  DashboardData({
    required this.user,
    required this.calories,
    required this.activities,
    this.weightGoal,
    this.latestBMI,
    required this.date,
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
  final double? targetWeight;
  final String? goalType;
  final DateTime? targetDate;
  final bool isActive;

  WeightGoal({
    this.id,
    this.targetWeight,
    this.goalType,
    this.targetDate,
    required this.isActive,
  });

  factory WeightGoal.fromJson(Map<String, dynamic> json) {
    return WeightGoal(
      id: json['id'] as String?,
      targetWeight: json['targetWeight'] != null
          ? (json['targetWeight'] as num).toDouble()
          : null,
      goalType: json['goalType'] as String?,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      isActive: json['isActive'] as bool,
    );
  }
}

class BMIRecord {
  final String? id;
  final double? bmi;
  final double? weight;
  final double? height;
  final String? category;
  final DateTime? recordedAt;

  BMIRecord({
    this.id,
    this.bmi,
    this.weight,
    this.height,
    this.category,
    this.recordedAt,
  });

  factory BMIRecord.fromJson(Map<String, dynamic> json) {
    return BMIRecord(
      id: json['id'] as String?,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      category: json['category'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : null,
    );
  }
}
