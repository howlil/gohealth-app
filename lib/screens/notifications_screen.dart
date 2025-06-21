import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Notifikasi',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      child: Stack(
        children: [
          // Background gradient bubbles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFilterTabs(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.error != null &&
                        provider.notifications.isEmpty) {
                      return _buildErrorState(provider.error!);
                    }

                    if (provider.notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () => provider.refreshAll(),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: provider.notifications.length +
                            (provider.isLoadingMore ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == provider.notifications.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final notification = provider.notifications[index];
                          return _buildNotificationItem(notification, provider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.unreadCount > 0
                        ? '${provider.unreadCount} notifikasi belum dibaca'
                        : 'Semua notifikasi sudah dibaca',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.unreadCount > 0)
              TextButton.icon(
                onPressed: () async {
                  final success = await provider.markAllAsRead();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Semua notifikasi ditandai sebagai sudah dibaca'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Tandai Semua'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    final filterOptions = [
      'Semua',
      'Belum Dibaca',
      'Sudah Dibaca',
      'Pengingat',
      'Pencapaian',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                _applyFilter(filter);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _applyFilter(String filter) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    switch (filter) {
      case 'Belum Dibaca':
        provider.setReadFilter(false);
        break;
      case 'Sudah Dibaca':
        provider.setReadFilter(true);
        break;
      case 'Pengingat':
        provider.setTypeFilter(NotificationType.MEAL_REMINDER);
        break;
      case 'Pencapaian':
        provider.setTypeFilter(NotificationType.GOAL_ACHIEVED);
        break;
      case 'Semua':
      default:
        provider.clearFilters();
        break;
    }
  }

  Widget _buildNotificationItem(
      NotificationModel notification, NotificationProvider provider) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          provider.markAsRead(notification.id);
        }
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.02),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  size: 20,
                  color: _getNotificationColor(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getNotificationColor(notification.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                onSelected: (action) async {
                  switch (action) {
                    case 'mark_read':
                      await provider.markAsRead(notification.id);
                      break;
                    case 'delete':
                      await _showDeleteConfirmation(notification, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done, size: 18),
                          SizedBox(width: 8),
                          Text('Tandai Dibaca'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content:
            const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteNotification(notification.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifikasi berhasil dihapus'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final provider =
                  Provider.of<NotificationProvider>(context, listen: false);
              provider.refreshAll();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.MEAL_REMINDER:
        return Colors.orange;
      case NotificationType.GOAL_ACHIEVED:
        return Colors.green;
      case NotificationType.BMI_UPDATE:
        return Colors.blue;
      case NotificationType.DAILY_CALORY_ACHIEVEMENT:
        return Colors.purple;
      case NotificationType.WEIGHT_GOAL_PROGRESS:
        return Colors.teal;
      case NotificationType.ACTIVITY_REMINDER:
        return Colors.red;
      case NotificationType.SYSTEM_UPDATE:
        return Colors.grey;
      case NotificationType.GENERAL:
      default:
        return AppColors.primary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.MEAL_REMINDER:
        return Icons.restaurant;
      case NotificationType.GOAL_ACHIEVED:
        return Icons.emoji_events;
      case NotificationType.BMI_UPDATE:
        return Icons.monitor_weight;
      case NotificationType.DAILY_CALORY_ACHIEVEMENT:
        return Icons.local_fire_department;
      case NotificationType.WEIGHT_GOAL_PROGRESS:
        return Icons.trending_up;
      case NotificationType.ACTIVITY_REMINDER:
        return Icons.directions_run;
      case NotificationType.SYSTEM_UPDATE:
        return Icons.system_update;
      case NotificationType.GENERAL:
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
