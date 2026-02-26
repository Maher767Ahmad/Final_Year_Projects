import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/app_theme.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final ApiService _apiService = ApiService();
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final endpoint = user.isSuperAdmin
          ? '/approvals/teachers'
          : '/approvals/students/${user.department}';
      final response = await _apiService.get(endpoint);

      if (response != null && response['data'] != null) {
        setState(() {
          _pendingUsers = (response['data'] as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String userId, bool approve) async {
    try {
      await _apiService.post('/approvals/update', {
        'user_id': userId,
        'status': approve ? 'approved' : 'rejected',
      });
      _fetchPendingUsers();
    } catch (e) {
      debugPrint('Error updating approval: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingUsers.length,
              itemBuilder: (context, index) =>
                  _buildUserApprovalCard(_pendingUsers[index]),
            ),
    );
  }

  Widget _buildUserApprovalCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: user.profilePicture != null
                    ? CachedNetworkImageProvider(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${user.role} | ${user.department}'),
            ),
            const SizedBox(height: 8),
            if (user.idCardUrl != null)
              GestureDetector(
                onTap: () => _showIdCardDialog(user.idCardUrl!),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: user.idCardUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _approveUser(user.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveUser(user.id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showIdCardDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
