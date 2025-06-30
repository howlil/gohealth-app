import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../utils/api_service.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_response.dart';
import 'fcm_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final ApiService _apiService = ApiService();
  final FCMService _fcmService = FCMService();

  factory NotificationService() => _instance;
  NotificationService._internal();

  // Getter to access FCM service for debugging
  FCMService get fcmService => _fcmService;

  /// Get notifications with pagination and filtering
  Future<ApiResponse<NotificationResponse>?> getNotifications({
    int page = 0,
    int limit = 20,
    bool? isRead,
    NotificationType? type,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (isRead != null) {
        queryParams['isRead'] = isRead.toString();
      }

      if (type != null) {
        queryParams['type'] = type.name;
      }

      final response = await _apiService.get(
        ApiEndpoints.notifications,
        requiresAuth: true,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        return ApiResponse<NotificationResponse>(
          success: true,
          message: response['message'] ?? 'Notifikasi berhasil dimuat',
          data: NotificationResponse.fromJson(response),
        );
      } else {
        return ApiResponse<NotificationResponse>(
          success: false,
          message: response['message'] ?? 'Gagal memuat notifikasi',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<NotificationResponse>(
        success: false,
        message: 'Error jaringan: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Get unread notification count
  Future<ApiResponse<UnreadCountResponse>?> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.notificationsUnreadCount,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<UnreadCountResponse>(
          success: true,
          message: response['message'] ??
              'Jumlah notifikasi belum dibaca berhasil dimuat',
          data: UnreadCountResponse.fromJson(response),
        );
      } else {
        return ApiResponse<UnreadCountResponse>(
          success: false,
          message: response['message'] ??
              'Gagal memuat jumlah notifikasi belum dibaca',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<UnreadCountResponse>(
        success: false,
        message: 'Error jaringan: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Mark notification as read
  Future<ApiResponse<NotificationModel>?> markAsRead(
      String notificationId) async {
    try {
      final response = await _apiService.patch(
        '${ApiEndpoints.notifications}/$notificationId/read',
        body: {},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<NotificationModel>(
          success: true,
          message: response['message'] ?? 'Notifikasi ditandai sudah dibaca',
          data: NotificationModel.fromJson(response['data']),
        );
      } else {
        return ApiResponse<NotificationModel>(
          success: false,
          message:
              response['message'] ?? 'Gagal menandai notifikasi sudah dibaca',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<NotificationModel>(
        success: false,
        message: 'Error jaringan: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>?> markAllAsRead() async {
    try {
      final response = await _apiService.patch(
        ApiEndpoints.notificationsReadAll,
        body: {},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message:
              response['message'] ?? 'Semua notifikasi ditandai sudah dibaca',
          data: response['data'] ?? {'count': 0},
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ??
              'Gagal menandai semua notifikasi sudah dibaca',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error jaringan: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Delete notification
  Future<ApiResponse<void>?> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.notifications}/$notificationId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message: response['message'] ?? 'Notifikasi berhasil dihapus',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Gagal menghapus notifikasi',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error jaringan: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Filter notifications locally by type
  List<NotificationModel> filterNotificationsByType(
    List<NotificationModel> notifications,
    NotificationType? type,
  ) {
    if (type == null) return notifications;
    return notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  /// Filter notifications locally by read status
  List<NotificationModel> filterNotificationsByReadStatus(
    List<NotificationModel> notifications,
    bool? isRead,
  ) {
    if (isRead == null) return notifications;
    return notifications
        .where((notification) => notification.isRead == isRead)
        .toList();
  }
}
