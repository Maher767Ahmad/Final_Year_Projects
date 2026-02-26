import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart';
import '../widgets/app_theme.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'book_detail_screen.dart';
import '../departments/all_departments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<BookModel> _recentBooks = [];
  bool _isLoading = true;
  bool _isOffline = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final response = await _apiService.get('/notifications/unread/${user.id}');
      if (response != null && response['count'] != null) {
        if (mounted) {
           setState(() {
             _unreadCount = int.parse(response['count'].toString());
           });
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await _apiService.get('/books/recent');
      if (response != null && response['data'] != null) {
        if (mounted) {
          setState(() {
            _recentBooks = (response['data'] as List)
                .map((b) => BookModel.fromJson(b))
                .toList();
            _isLoading = false;
            _isOffline = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isLoading = true);
            await _fetchDashboardData();
            await _fetchUnreadCount();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'User'}!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'What would you like to read today?',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            _fetchUnreadCount(); // Refresh count on return
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            size: 28,
                          ),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadCount > 9 ? '9+' : '',
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold
                                  ),
                                ), 
                              )
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
  
                if (_isOffline) _buildOfflineBanner(),
  
                // Search Bar
                GestureDetector(
                  onTap: () {
                    if (_isOffline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search is only available online.')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white38),
                        const SizedBox(width: 12),
                        Text(
                          _isOffline ? 'Search unavailable (Offline)' : 'Search books, authors, subjects...',
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
  
                // Recent Uploads Section
                _buildSectionHeader('Recent Uploads', () {
                  if (_isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please connect to internet to browse all departments.')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllDepartmentsScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _isOffline ? _buildOfflineCard() : (_isLoading ? _buildShimmerList() : _buildRecentBooksList()),
  
                const SizedBox(height: 32),
  
                // Recommended for You (Based on Department)
                _buildSectionHeader(
                  'Recommended for ${user?.department ?? "You"}',
                  () {
                    if (_isOffline) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllDepartmentsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _isOffline ? _buildOfflineCard() : (_isLoading ? _buildShimmerList() : _buildRecentBooksList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Some features are limited.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Cannot Load Books Offline',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection to see latest books.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // Navigation to Profile is index 4 in MainAppNavigation
              // We can use a trick or just tell them to use the bottom bar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Go to Profile > Downloaded Books to read offline.')),
              );
            },
            icon: const Icon(Icons.download_done, size: 18),
            label: const Text('View Downloaded Books'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBooksList() {
    if (_recentBooks.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No books available yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentBooks.length,
        itemBuilder: (context, index) {
          return BookCard(
            book: _recentBooks[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(book: _recentBooks[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.05),
            highlightColor: Colors.white10,
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}
