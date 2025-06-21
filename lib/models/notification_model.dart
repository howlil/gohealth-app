enum NotificationType {
  DAILY_CALORY_ACHIEVEMENT,
  MEAL_REMINDER,
  WEIGHT_GOAL_PROGRESS,
  BMI_UPDATE,
  ACTIVITY_REMINDER,
  GOAL_ACHIEVED,
  SYSTEM_UPDATE,
  GENERAL
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseNotificationType(json['type']?.toString()),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type?.toUpperCase()) {
      case 'DAILY_CALORY_ACHIEVEMENT':
        return NotificationType.DAILY_CALORY_ACHIEVEMENT;
      case 'MEAL_REMINDER':
        return NotificationType.MEAL_REMINDER;
      case 'WEIGHT_GOAL_PROGRESS':
        return NotificationType.WEIGHT_GOAL_PROGRESS;
      case 'BMI_UPDATE':
        return NotificationType.BMI_UPDATE;
      case 'ACTIVITY_REMINDER':
        return NotificationType.ACTIVITY_REMINDER;
      case 'GOAL_ACHIEVED':
        return NotificationType.GOAL_ACHIEVED;
      case 'SYSTEM_UPDATE':
        return NotificationType.SYSTEM_UPDATE;
      case 'GENERAL':
      default:
        return NotificationType.GENERAL;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.DAILY_CALORY_ACHIEVEMENT:
        return 'Pencapaian Kalori';
      case NotificationType.MEAL_REMINDER:
        return 'Pengingat Makan';
      case NotificationType.WEIGHT_GOAL_PROGRESS:
        return 'Progress Berat Badan';
      case NotificationType.BMI_UPDATE:
        return 'Update BMI';
      case NotificationType.ACTIVITY_REMINDER:
        return 'Pengingat Aktivitas';
      case NotificationType.GOAL_ACHIEVED:
        return 'Target Tercapai';
      case NotificationType.SYSTEM_UPDATE:
        return 'Update Sistem';
      case NotificationType.GENERAL:
        return 'Umum';
    }
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int totalCount;
  final int currentPage;
  final int limit;
  final bool hasNextPage;
  final bool hasPreviousPage;

  NotificationResponse({
    required this.notifications,
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final notificationsData = data['notifications'] ?? data['data'] ?? [];

    return NotificationResponse(
      notifications: (notificationsData as List)
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount']?.toInt() ?? 0,
      currentPage: data['currentPage']?.toInt() ?? 0,
      limit: data['limit']?.toInt() ?? 20,
      hasNextPage: data['hasNextPage'] == true,
      hasPreviousPage: data['hasPreviousPage'] == true,
    );
  }
}

class UnreadCountResponse {
  final int count;

  UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UnreadCountResponse(
      count: data['count']?.toInt() ?? 0,
    );
  }
}
