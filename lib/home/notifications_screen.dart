import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';
import '../models/book_model.dart';
import '../widgets/app_theme.dart';
import 'book_detail_screen.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _handleNotificationTap(AppNotification n) async {
    if (n.type == 'approval') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if ((n.type == 'book_request' || n.type == 'book_upload') && n.relatedId != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final response = await _apiService.get('/books/id/${n.relatedId}');
        Navigator.pop(context); // Remove loading

        if (response != null && response['data'] != null) {
          final book = BookModel.fromJson(response['data']);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book details not found')),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Remove loading
        debugPrint('Error fetching book details for navigation: $e');
      }
    }
  }

  Future<void> _fetchNotifications() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final response = await _apiService.get('/notifications/user/${user.id}');
      if (response != null && response['data'] != null) {
        if (mounted) {
          setState(() {
            _notifications = (response['data'] as List)
                .map((n) => AppNotification.fromJson(n))
                .toList();
            _isLoading = false;
          });
          
          // After fetching, if there are unread notifications, mark them all as read correctly
          if (_notifications.any((n) => !n.readStatus)) {
            _markAllAsRead(user.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      await _apiService.put('/notifications/read-all/$userId', {});
      // Update local state so dots disappear immediately
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            return AppNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              message: n.message,
              relatedId: n.relatedId,
              readStatus: true,
              createdAt: n.createdAt,
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return ListTile(
                  onTap: () => _handleNotificationTap(n),
                  leading: CircleAvatar(
                    backgroundColor: n.type == 'approval'
                        ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      n.type == 'approval' ? Icons.verified_user : Icons.book,
                      color: n.type == 'approval'
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    n.message,
                    style: TextStyle(
                      fontWeight: n.readStatus
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, hh:mm a').format(n.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: !n.readStatus
                      ? const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppTheme.primaryColor,
                        )
                      : null,
                );
              },
            ),
    );
  }
}
