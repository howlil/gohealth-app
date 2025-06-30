import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingMore = false;

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
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool? get filterIsRead => _filterIsRead;
  NotificationType? get filterType => _filterType;

  // Konstruktor dengan penanganan error
  NotificationProvider() {
    // Inisialisasi dengan nilai default dan tangani error dengan aman
    _unreadCount = 0;
    _notifications = [];
  }

  /// Initialize notifications (called from UI)
  Future<void> initialize() async {
    debugPrint('🔔 Initializing NotificationProvider');
    await Future.wait([
      loadNotifications(refresh: true),
      loadUnreadCount(),
    ]);
  }

  /// Load notifications (refresh)
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMoreData = true;
      _notifications.clear();
    }

    if (isLoading || (_isLoadingMore && !refresh)) return;

    if (refresh) {
      setLoading(true);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    clearMessages();

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

        // Show success message for refresh only
        if (refresh) {
          setSuccess(response.message ?? 'Notifikasi berhasil dimuat');
        }
      } else {
        final errorMessage = response?.message ?? 'Gagal memuat notifikasi';
        setError(errorMessage);
      }
    } catch (e) {
      setError('Terjadi kesalahan saat memuat notifikasi: ${e.toString()}');
    } finally {
      setLoading(false);
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
      } else {
        _unreadCount = 0;
        notifyListeners();
        // Don't show error for unread count failure
      }
    } catch (e) {
      _unreadCount = 0;
      notifyListeners();
      // Don't show error for unread count failure
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);

      if (response?.success == true) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final wasUnread = !_notifications[index].isRead;
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );

          if (wasUnread) {
            _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
          }

          notifyListeners();
        }

        setSuccess(response?.message ?? 'Notifikasi ditandai sudah dibaca');
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal menandai notifikasi sudah dibaca';
        setError(errorMessage);
        return false;
      }
    } catch (e) {
      setError('Terjadi kesalahan saat menandai notifikasi: ${e.toString()}');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();

      if (response?.success == true) {
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

        setSuccess(
            response?.message ?? 'Semua notifikasi ditandai sudah dibaca');
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal menandai semua notifikasi sudah dibaca';
        setError(errorMessage);
        return false;
      }
    } catch (e) {
      setError(
          'Terjadi kesalahan saat menandai semua notifikasi: ${e.toString()}');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response =
          await _notificationService.deleteNotification(notificationId);

      if (response?.success == true) {
        final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => _notifications.isNotEmpty
              ? _notifications.first
              : _createDummyNotification(),
        );

        _notifications.removeWhere((n) => n.id == notificationId);

        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }

        notifyListeners();

        setSuccess(response?.message ?? 'Notifikasi berhasil dihapus');
        return true;
      } else {
        final errorMessage = response?.message ?? 'Gagal menghapus notifikasi';
        setError(errorMessage);
        return false;
      }
    } catch (e) {
      setError('Terjadi kesalahan saat menghapus notifikasi: ${e.toString()}');
      return false;
    }
  }

  /// Apply filters
  Future<void> applyFilter({
    bool? isRead,
    NotificationType? type,
  }) async {
    _filterIsRead = isRead;
    _filterType = type;

    await loadNotifications(refresh: true);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    _filterIsRead = null;
    _filterType = null;

    await loadNotifications(refresh: true);
  }

  /// Helper to create dummy notification (fallback)
  NotificationModel _createDummyNotification() {
    return NotificationModel(
      id: '',
      title: '',
      message: '',
      type: NotificationType.GENERAL,
      isRead: false,
      createdAt: DateTime.now(),
      data: {},
    );
  }
}
