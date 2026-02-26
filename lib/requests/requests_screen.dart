import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/book_request_model.dart';
import '../widgets/app_theme.dart';
import '../upload/upload_book_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final ApiService _apiService = ApiService();
  final _requestController = TextEditingController();
  List<BookRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      String endpoint;
      if (user.isSuperAdmin) {
        endpoint = '/book_requests/all';
      } else if (user.isTeacher) {
        endpoint = '/book_requests/department/${user.department}';
      } else {
        endpoint = '/book_requests/student/${user.id}';
      }

      final response = await _apiService.get(endpoint);
      if (response != null && response['data'] != null) {
        setState(() {
          _requests = (response['data'] as List)
              .map((r) => BookRequestModel.fromJson(r))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_requestController.text.isEmpty) return;

    final user = Provider.of<AuthService>(context, listen: false).currentUser!;
    try {
      final response = await _apiService.post('/book_requests/submit', {
        'student_id': user.id,
        'department': user.department,
        'book_name': _requestController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Request submitted!')),
        );
      }
      
      _requestController.clear();
      _fetchRequests();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Requests')),
      body: Column(
        children: [
          if (user?.isStudent ?? false)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _showRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Book Request'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) =>
                          _buildRequestCard(_requests[index], user!),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BookRequestModel request, dynamic user) {
    // Both Teachers and Super Admins can fulfill pending requests
    final bool canFulfill = (user.isTeacher || user.isSuperAdmin) && request.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.bookName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested by: ${request.studentName}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(request.requestedDate)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),

            if (request.status == 'fulfilled' &&
                request.fulfilledBy != null) ...[
              const Divider(height: 24),
              Text(
                'Fulfilled by: ${request.fulfilledBy}',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            if (canFulfill) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadBookScreen(
                        requestId: request.id,
                        initialTitle: request.bookName,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    side: const BorderSide(color: AppTheme.secondaryColor),
                  ),
                  child: const Text('Fulfill Request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'fulfilled':
        color = AppTheme.secondaryColor;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('New Book Request'),
        content: TextField(
          controller: _requestController,
          decoration: const InputDecoration(
            hintText: 'Enter book name or topic...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
