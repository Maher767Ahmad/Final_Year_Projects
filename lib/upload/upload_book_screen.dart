import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../constants.dart';

class UploadBookScreen extends StatefulWidget {
  final int? requestId;
  final String? initialTitle;

  const UploadBookScreen({
    super.key,
    this.requestId,
    this.initialTitle,
  });

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedSubject;
  String _accessType = 'read'; // 'read' or 'download'
  File? _selectedFile;
  bool _isUploading = false;
  List<String> _availableSubjects = [];

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    // Initialize after build to access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForUser();
    });
  }

  void _initForUser() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    if (user.isSuperAdmin) {
       // Super Admin: Start with first department, or let them choose
       // We leave _selectedDepartment null so they must choose
    } else {
       // Teacher or Student: Department is fixed
       _selectedDepartment = user.department;
       _updateAvailableSubjects();
    }
    setState(() {});
  }

  void _updateAvailableSubjects() {
    if (_selectedDepartment == null) {
      _availableSubjects = [];
      return;
    }

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    if (user.isTeacher && !user.isSuperAdmin) {
       // Teacher: Only approved subjects
       _availableSubjects = user.approvedSubjects;
    } else {
       // Super Admin or Student: All subjects in department
       _availableSubjects = AppConstants.subjectsMap[_selectedDepartment] ?? [];
    }
    
    // Reset selected subject if it's no longer valid
    if (_selectedSubject != null && !_availableSubjects.contains(_selectedSubject)) {
      _selectedSubject = null;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() ||
        _selectedFile == null ||
        _selectedSubject == null || 
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a file'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser!;

    try {
      // 1. Upload file to Firebase Storage
      final fileUrl = await _storageService.uploadBook(
        _selectedFile!,
        _selectedDepartment!,
      );

      // 2. Save metadata to backend
      await _apiService.post('/books/upload', {
        'title': _titleController.text,
        'author': _authorController.text,
        'department': _selectedDepartment,
        'subject': _selectedSubject,
        'file_url': fileUrl,
        'access_type': _accessType,
        'uploaded_by': user.id,
        'request_id': widget.requestId, // Pass the request ID if it exists
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSuperAdmin = user.isSuperAdmin;
    final isDepartmentFixed = !isSuperAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Book Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter author' : null,
              ),
              const SizedBox(height: 16),

              // Department Selection
              if (isDepartmentFixed)
                TextFormField(
                  initialValue: _selectedDepartment,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedDepartment = v;
                      _updateAvailableSubjects();
                    });
                  },
                  validator: (v) => v == null ? 'Select department' : null,
                ),

              const SizedBox(height: 16),

              // Subject Selection
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: _availableSubjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubject = v),
                validator: (v) => v == null ? 'Select subject' : null,
              ),
              if (_availableSubjects.isEmpty && _selectedDepartment != null)
                 const Padding(
                   padding: EdgeInsets.only(top: 8.0),
                   child: Text(
                     'No subjects available. Teachers can only upload to approved subjects.',
                     style: TextStyle(color: Colors.redAccent, fontSize: 12),
                   ),
                 ),

              const SizedBox(height: 16),

              const Text(
                'Access Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Read Only'),
                      value: 'read',
                      groupValue: _accessType,
                      onChanged: (v) => setState(() => _accessType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Downloadable'),
                      value: 'download',
                      groupValue: _accessType,
                      onChanged: (v) => setState(() => _accessType = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedFile != null
                      ? Center(
                          child: Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select PDF / Document',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isUploading ? null : _handleUpload,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Upload Book',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
