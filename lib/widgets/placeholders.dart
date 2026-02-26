import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Library')),
      body: const Center(child: Text('Home Dashboard - Recent Books')),
    );
  }
}

class MyDepartmentScreen extends StatelessWidget {
  const MyDepartmentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Department')),
      body: const Center(child: Text('Department-wise Books')),
    );
  }
}

class AllDepartmentsScreen extends StatelessWidget {
  const AllDepartmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Departments')),
      body: const Center(child: Text('Browse All Books')),
    );
  }
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Requests')),
      body: const Center(child: Text('Requests & Fulfilment')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: Text('User Profile & ID Card')),
    );
  }
}
