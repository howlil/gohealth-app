import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../utils/api_service.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_response.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final ApiService _apiService = ApiService();

  factory NotificationService() => _instance;
  NotificationService._internal();

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

      debugPrint('Notifications response: $response');

      if (response['success'] == true) {
        return ApiResponse<NotificationResponse>(
          success: true,
          message:
              response['message'] ?? 'Notifications retrieved successfully',
          data: NotificationResponse.fromJson(response),
        );
      } else {
        return ApiResponse<NotificationResponse>(
          success: false,
          message: response['message'] ?? 'Failed to get notifications',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return ApiResponse<NotificationResponse>(
        success: false,
        message: 'Network error: ${e.toString()}',
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

      debugPrint('Unread count response: $response');

      if (response['success'] == true) {
        return ApiResponse<UnreadCountResponse>(
          success: true,
          message: response['message'] ?? 'Unread count retrieved successfully',
          data: UnreadCountResponse.fromJson(response),
        );
      } else {
        return ApiResponse<UnreadCountResponse>(
          success: false,
          message: response['message'] ?? 'Failed to get unread count',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return ApiResponse<UnreadCountResponse>(
        success: false,
        message: 'Network error: ${e.toString()}',
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

      debugPrint('Mark as read response: $response');

      if (response['success'] == true) {
        return ApiResponse<NotificationModel>(
          success: true,
          message: response['message'] ?? 'Notification marked as read',
          data: NotificationModel.fromJson(response['data']),
        );
      } else {
        return ApiResponse<NotificationModel>(
          success: false,
          message: response['message'] ?? 'Failed to mark notification as read',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return ApiResponse<NotificationModel>(
        success: false,
        message: 'Network error: ${e.toString()}',
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

      debugPrint('Mark all as read response: $response');

      if (response['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response['message'] ?? 'All notifications marked as read',
          data: response['data'] ?? {'count': 0},
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message:
              response['message'] ?? 'Failed to mark all notifications as read',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
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

      debugPrint('Delete notification response: $response');

      if (response['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message: response['message'] ?? 'Notification deleted successfully',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to delete notification',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
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
