class IBMHistory {
  final String id;
  final double height;
  final double weight;
  final double bmi;
  final String status;
  final DateTime recordedAt;

  IBMHistory({
    required this.id,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.status,
    required this.recordedAt,
  });

  factory IBMHistory.fromJson(Map<String, dynamic> json) {
    try {
      return IBMHistory(
        id: json['id']?.toString() ?? '',
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? '',
        recordedAt: json['recordedAt'] != null
            ? DateTime.parse(json['recordedAt'].toString())
            : DateTime.now(),
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
    };
  }
}
