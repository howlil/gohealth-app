class BMIGoal {
  final String id;
  final String userId;
  final double startWeight;
  final double targetWeight;
  final DateTime startDate;
  final DateTime targetDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double currentWeight;
  final double progress;
  final double weightLost;
  final double weightRemaining;

  BMIGoal({
    required this.id,
    required this.userId,
    required this.startWeight,
    required this.targetWeight,
    required this.startDate,
    required this.targetDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.currentWeight = 0.0,
    this.progress = 0.0,
    this.weightLost = 0.0,
    this.weightRemaining = 0.0,
  });

  factory BMIGoal.fromJson(Map<String, dynamic> json) {
    // Parse date with custom format (DD-MM-YYYY)
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      // Check if the date is in DD-MM-YYYY format
      if (dateStr.contains('-') && dateStr.split('-').length == 3) {
        try {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (e) {
          print('Error parsing date: $dateStr, $e');
        }
      }

      // Try standard ISO format as fallback
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing ISO date: $dateStr, $e');
        return DateTime.now();
      }
    }

    return BMIGoal(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      startWeight: (json['startWeight'] as num?)?.toDouble() ?? 0.0,
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 0.0,
      startDate: parseDate(json['startDate']?.toString()),
      targetDate: parseDate(json['targetDate']?.toString()),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']?.toString()),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 0.0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      weightLost: (json['weightLost'] as num?)?.toDouble() ?? 0.0,
      weightRemaining: (json['weightRemaining'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }

    return {
      'id': id,
      'userId': userId,
      'startWeight': startWeight,
      'targetWeight': targetWeight,
      'startDate': formatDate(startDate),
      'targetDate': formatDate(targetDate),
      'isActive': isActive,
      'createdAt': formatDate(createdAt),
      'updatedAt': formatDate(updatedAt),
      'currentWeight': currentWeight,
      'progress': progress,
      'weightLost': weightLost,
      'weightRemaining': weightRemaining,
    };
  }
}
