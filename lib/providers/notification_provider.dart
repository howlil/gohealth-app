import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  bool _hasMoreData = true;
  static const int _limit = 20;

  // Filtering
  bool? _filterIsRead;
  NotificationType? _filterType;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool? get filterIsRead => _filterIsRead;
  NotificationType? get filterType => _filterType;

  /// Load notifications (refresh)
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMoreData = true;
      _notifications.clear();
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    if (refresh) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }

    _error = null;
    notifyListeners();

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
        isRead: _filterIsRead,
        type: _filterType,
      );

      if (response?.success == true && response?.data != null) {
        final notificationResponse = response!.data!;

        if (refresh) {
          _notifications = notificationResponse.notifications;
        } else {
          _notifications.addAll(notificationResponse.notifications);
        }

        _hasMoreData = notificationResponse.hasNextPage;
        _currentPage++;
      } else {
        _error = response?.message ?? 'Failed to load notifications';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!_hasMoreData || _isLoadingMore) return;
    await loadNotifications(refresh: false);
  }

  /// Get unread count
  Future<void> loadUnreadCount() async {
    try {
      final response = await _notificationService.getUnreadCount();

      if (response?.success == true && response?.data != null) {
        _unreadCount = response!.data!.count;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);

      if (response?.success == true) {
        // Update local notification
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );

          // Decrease unread count if notification was unread
          if (!_notifications[index].isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
          }

          notifyListeners();
        }
        return true;
      } else {
        _error = response?.message ?? 'Failed to mark notification as read';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking notification as read: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();

      if (response?.success == true) {
        // Update all local notifications to read
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        }

        _unreadCount = 0;
        notifyListeners();
        return true;
      } else {
        _error =
            response?.message ?? 'Failed to mark all notifications as read';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response =
          await _notificationService.deleteNotification(notificationId);

      if (response?.success == true) {
        // Remove from local list
        final notification = _notifications.firstWhere(
            (n) => n.id == notificationId,
            orElse: () => _notifications.first);
        _notifications.removeWhere((n) => n.id == notificationId);

        // Decrease unread count if notification was unread
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }

        notifyListeners();
        return true;
      } else {
        _error = response?.message ?? 'Failed to delete notification';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting notification: $e');
      notifyListeners();
      return false;
    }
  }

  /// Set filter for read status
  void setReadFilter(bool? isRead) {
    _filterIsRead = isRead;
    loadNotifications(refresh: true);
  }

  /// Set filter for notification type
  void setTypeFilter(NotificationType? type) {
    _filterType = type;
    loadNotifications(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _filterIsRead = null;
    _filterType = null;
    loadNotifications(refresh: true);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get filtered notifications (for local filtering)
  List<NotificationModel> getFilteredNotifications({
    bool? isRead,
    NotificationType? type,
  }) {
    var filtered = List<NotificationModel>.from(_notifications);

    if (isRead != null) {
      filtered = filtered.where((n) => n.isRead == isRead).toList();
    }

    if (type != null) {
      filtered = filtered.where((n) => n.type == type).toList();
    }

    return filtered;
  }

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get read notifications
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  /// Initialize provider (load initial data)
  Future<void> initialize() async {
    await Future.wait([
      loadNotifications(refresh: true),
      loadUnreadCount(),
    ]);
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadNotifications(refresh: true),
      loadUnreadCount(),
    ]);
  }
}
