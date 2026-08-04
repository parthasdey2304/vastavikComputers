import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _dobController = TextEditingController();
  final _firestoreService = FirestoreService();

  String _selectedBoard = 'ICSE';
  String _selectedClass = 'Class 10';
  String _selectedLanguage = 'Java';
  bool _isSaving = false;

  final List<String> _boards = ['ICSE', 'CBSE'];
  final List<String> _classes = [
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12',
  ];
  final List<String> _languages = ['Java', 'Python', 'C', 'C++', 'JavaScript'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userModel = UserModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        school: _schoolController.text.trim(),
        studentClass: _selectedClass,
        board: _selectedBoard,
        preferredLanguage: _selectedLanguage,
      );

      await _firestoreService.createUserProfile(userModel);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Cannot skip profile setup
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button
          title: Text('Complete Your Profile', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person_add, size: 50, color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text('Tell us about yourself!', style: TextStyle(fontSize: 16, color: context.appTextSecondary)),
              ),
              SizedBox(height: 32),

              // Email
              _buildLabel('Email Address'),
              SizedBox(height: 8),
              TextFormField(
                initialValue: FirebaseAuth.instance.currentUser?.email ?? '',
                readOnly: true,
                decoration: _inputDecoration('Email Address', Icons.email_outlined).copyWith(
                  fillColor: context.appSurface,
                ),
              ),
              SizedBox(height: 20),

              // Name
              _buildLabel('Full Name'),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter your full name', Icons.person_outline),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 20),

              // Date of Birth
              _buildLabel('Date of Birth'),
              SizedBox(height: 8),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDecoration('Pick your date of birth', Icons.calendar_today),
                validator: (val) => val == null || val.trim().isEmpty ? 'Date of birth is required' : null,
              ),
              SizedBox(height: 20),

              // School
              _buildLabel('School Name'),
              SizedBox(height: 8),
              TextFormField(
                controller: _schoolController,
                decoration: _inputDecoration('Enter your school name', Icons.school_outlined),
                validator: (val) => val == null || val.trim().isEmpty ? 'School name is required' : null,
              ),
              SizedBox(height: 20),

              // Board
              _buildLabel('Board'),
              SizedBox(height: 8),
              _buildDropdown(_selectedBoard, _boards, (val) => setState(() => _selectedBoard = val!)),
              SizedBox(height: 20),

              // Class
              _buildLabel('Class'),
              SizedBox(height: 8),
              _buildDropdown(_selectedClass, _classes, (val) => setState(() => _selectedClass = val!)),
              SizedBox(height: 20),

              // Preferred Language
              _buildLabel('Preferred Language'),
              SizedBox(height: 8),
              _buildDropdown(_selectedLanguage, _languages, (val) => setState(() => _selectedLanguage = val!)),
              SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appTextPrimary),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.appSurface),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.appSurface),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appSurface),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
