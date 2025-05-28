class ProfileStats {
  final int totalWorkouts;
  final double totalCaloriesBurned;
  final int totalMinutesExercised;
  final double averageCaloriesPerWorkout;
  final double averageMinutesPerWorkout;
  final int streakDays;

  const ProfileStats({
    required this.totalWorkouts,
    required this.totalCaloriesBurned,
    required this.totalMinutesExercised,
    required this.averageCaloriesPerWorkout,
    required this.averageMinutesPerWorkout,
    required this.streakDays,
  });

  ProfileStats copyWith({
    int? totalWorkouts,
    double? totalCaloriesBurned,
    int? totalMinutesExercised,
    double? averageCaloriesPerWorkout,
    double? averageMinutesPerWorkout,
    int? streakDays,
  }) {
    return ProfileStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      totalMinutesExercised:
          totalMinutesExercised ?? this.totalMinutesExercised,
      averageCaloriesPerWorkout:
          averageCaloriesPerWorkout ?? this.averageCaloriesPerWorkout,
      averageMinutesPerWorkout:
          averageMinutesPerWorkout ?? this.averageMinutesPerWorkout,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalCaloriesBurned': totalCaloriesBurned,
      'totalMinutesExercised': totalMinutesExercised,
      'averageCaloriesPerWorkout': averageCaloriesPerWorkout,
      'averageMinutesPerWorkout': averageMinutesPerWorkout,
      'streakDays': streakDays,
    };
  }

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalWorkouts: json['totalWorkouts'] as int,
      totalCaloriesBurned: json['totalCaloriesBurned'] as double,
      totalMinutesExercised: json['totalMinutesExercised'] as int,
      averageCaloriesPerWorkout: json['averageCaloriesPerWorkout'] as double,
      averageMinutesPerWorkout: json['averageMinutesPerWorkout'] as double,
      streakDays: json['streakDays'] as int,
    );
  }

  // Add a factory constructor for empty stats
  factory ProfileStats.empty() {
    return const ProfileStats(
      totalWorkouts: 0,
      totalCaloriesBurned: 0,
      totalMinutesExercised: 0,
      averageCaloriesPerWorkout: 0,
      averageMinutesPerWorkout: 0,
      streakDays: 0,
    );
  }
}
