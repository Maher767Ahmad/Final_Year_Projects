import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart';
import '../widgets/app_theme.dart';
import '../upload/upload_book_screen.dart';
import '../home/book_detail_screen.dart';

class MyDepartmentScreen extends StatefulWidget {
  const MyDepartmentScreen({super.key});

  @override
  State<MyDepartmentScreen> createState() => _MyDepartmentScreenState();
}

class _MyDepartmentScreenState extends State<MyDepartmentScreen> {
  final ApiService _apiService = ApiService();
  Map<String, List<BookModel>> _subjectWiseBooks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartmentBooks();
  }

  Future<void> _fetchDepartmentBooks() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dept = authService.currentUser?.department;

    if (dept == null) return;

    try {
      final response = await _apiService.get('/books/department/$dept');
      if (response != null && response['data'] != null) {
        final List books = response['data'];
        final Map<String, List<BookModel>> map = {};

        for (var b in books) {
          final book = BookModel.fromJson(b);
          if (map[book.subject] == null) map[book.subject] = [];
          map[book.subject]!.add(book);
        }

        setState(() {
          _subjectWiseBooks = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dept books: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('${user?.department} Department'),
        actions: [
          IconButton(
            onPressed: _fetchDepartmentBooks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _subjectWiseBooks.isEmpty
                  ? [
                      const Center(
                        child: Text(
                          'No books in this department yet.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ]
                  : _subjectWiseBooks.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectHeader(entry.key),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                final book = entry.value[index];
                                final bool canDelete = user != null && 
                                  (user.isSuperAdmin || 
                                  (user.isTeacher && user.approvedSubjects.contains(book.subject)));

                                return BookCard(
                                  book: book,
                                  onTap: () => _handleBookTap(book),
                                  onDelete: canDelete ? () => _confirmDelete(book) : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadBookScreen()),
        ),
        label: const Text('Upload Book'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _confirmDelete(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Book?'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/books/delete/${book.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
        _fetchDepartmentBooks(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e')),
        );
      }
    }
  }

  void _handleBookTap(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
  }

  Widget _buildSubjectHeader(String subject) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
