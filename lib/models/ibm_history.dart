class IBMHistory {
  final String? id;
  final DateTime date;
  final double bmi;
  final double height;
  final double weight;
  final String category;
  final DateTime? recordedAt;

  IBMHistory({
    this.id,
    required this.date,
    required this.bmi,
    required this.height,
    required this.weight,
    required this.category,
    this.recordedAt,
  });

  factory IBMHistory.fromJson(Map<String, dynamic> json) {
    return IBMHistory(
      id: json['id'] as String?,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      bmi: (json['bmi'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      category: json['category'] as String,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bmi': bmi,
      'height': height,
      'weight': weight,
      'category': category,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }
}
