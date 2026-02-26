import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_theme.dart';
import '../constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Student';
  String _selectedDepartment = 'Botany';
  List<String> _selectedSubjects = [];
  XFile? _idCardImage;



  final StorageService _storageService = StorageService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _idCardImage = pickedFile);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your ID Card front image')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      debugPrint('Starting signup process...');

      // 1. Upload ID Card
      debugPrint('Uploading ID card...');
      final idCardUrl = await _storageService.uploadIdCard(
        _idCardImage!,
        _emailController.text,
      );
      debugPrint('ID card uploaded: $idCardUrl');

      // 2. Register
      debugPrint('Registering user...');
      await authService.signup(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        role: _selectedRole == 'Student' ? 'Student' : 'Teacher Admin',
        department: _selectedDepartment,
        subjects: _selectedRole == 'Teacher' ? _selectedSubjects : null,
        idCardUrl: idCardUrl,
      );
      debugPrint('User registered successfully');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Awaiting approval.'),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Digital Library',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 24),

              // Role Selection
              const Text(
                'I am a:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Student'),
                      value: 'Student',
                      groupValue: _selectedRole,
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Teacher'),
                      value: 'Teacher',
                      groupValue: _selectedRole,
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'University Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),

              // Department Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.domain),
                ),
                items: AppConstants.departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedDepartment = v!;
                    _selectedSubjects = [];
                  });
                },
              ),

              if (_selectedRole == 'Teacher') ...[
                const SizedBox(height: 24),
                const Text(
                  'Select Subjects to Teach:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: AppConstants.subjectsMap[_selectedDepartment]!.map((s) {
                    final isSelected = _selectedSubjects.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected)
                            _selectedSubjects.add(s);
                          else
                            _selectedSubjects.remove(s);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),

              // ID Card Upload
              const Text(
                'Verification ID Card (Front):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white24,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _idCardImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: _idCardImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(_idCardImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload ID Card image',
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: authService.isLoading ? null : _handleSignup,
                  child: authService.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
