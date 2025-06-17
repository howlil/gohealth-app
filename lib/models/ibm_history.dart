class IBMHistory {
  final String id;
  final double height;
  final double weight;
  final double bmi;
  final String status;
  final DateTime recordedAt;
  final Map<String, dynamic>? nutritionSummary;

  IBMHistory({
    required this.id,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.status,
    required this.recordedAt,
    this.nutritionSummary,
  });

  factory IBMHistory.fromJson(Map<String, dynamic> json) {
    try {
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

      return IBMHistory(
        id: json['id']?.toString() ?? '',
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? '',
        recordedAt: parseDate(json['recordedAt']?.toString()),
        nutritionSummary: json['nutritionSummary'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing IBMHistory: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'status': status,
      'recordedAt': recordedAt.toIso8601String(),
      'nutritionSummary': nutritionSummary,
    };
  }
}
