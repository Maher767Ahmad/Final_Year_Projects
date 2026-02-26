import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart';
import '../widgets/app_theme.dart';
import '../home/book_detail_screen.dart';
import '../constants.dart';

class AllDepartmentsScreen extends StatefulWidget {
  const AllDepartmentsScreen({super.key});

  @override
  State<AllDepartmentsScreen> createState() => _AllDepartmentsScreenState();
}

class _AllDepartmentsScreenState extends State<AllDepartmentsScreen> {
  final ApiService _apiService = ApiService();
  final List<String> _departments = AppConstants.departments;
  String? _expandedDepartment;
  List<BookModel> _deptBooks = [];
  bool _isFetchingBooks = false;

  Future<void> _fetchBooksForDept(String dept) async {
    setState(() {
      _expandedDepartment = dept;
      _isFetchingBooks = true;
    });

    try {
      final response = await _apiService.get('/books/department/$dept');
      if (response != null && response['data'] != null) {
        setState(() {
          _deptBooks = (response['data'] as List)
              .map((b) => BookModel.fromJson(b))
              .toList();
          _isFetchingBooks = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching books: $e');
      setState(() => _isFetchingBooks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Departments')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departments.length,
        itemBuilder: (context, index) {
          final dept = _departments[index];
          final isExpanded = _expandedDepartment == dept;

          return Column(
            children: [
              GestureDetector(
                onTap: () => isExpanded
                    ? setState(() => _expandedDepartment = null)
                    : _fetchBooksForDept(dept),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? AppTheme.primaryColor
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dept,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                if (_isFetchingBooks)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (_deptBooks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No books in this department',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                else
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _deptBooks.length,
                      itemBuilder: (context, index) =>
                          BookCard(
                                book: _deptBooks[index],
                                onTap: () => _handleBookTap(_deptBooks[index]),
                              ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }

  void _handleBookTap(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
  }
}
