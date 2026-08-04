import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedBoard = 'ICSE';
  String _selectedClass = 'Class 10';
  String _selectedLanguage = 'Java';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _boards = ['ICSE', 'CBSE'];
  final List<String> _classes = ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12'];
  final List<String> _languages = ['Java', 'Python', 'C', 'C++', 'JavaScript'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final user = await _firestoreService.getUserProfile(uid);
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.name;
        _schoolController.text = user.school;
        _dobController.text = user.dateOfBirth;
        _selectedBoard = user.board;
        _selectedClass = user.studentClass;
        _selectedLanguage = user.preferredLanguage;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _firestoreService.updateUserProfile(uid, {
        'name': _nameController.text.trim(),
        'school': _schoolController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'board': _selectedBoard,
        'studentClass': _selectedClass,
        'preferredLanguage': _selectedLanguage,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Edit Profile', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ResponsiveWrapper(
              child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _buildLabel('Full Name'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person_outline),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 20),
                    _buildLabel('Date of Birth'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: _inputDecoration('Date of Birth', Icons.calendar_today),
                    ),
                    SizedBox(height: 20),
                    _buildLabel('School Name'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _schoolController,
                      decoration: _inputDecoration('School', Icons.school_outlined),
                    ),
                    SizedBox(height: 20),
                    _buildLabel('Board'),
                    SizedBox(height: 8),
                    _buildDropdown(_selectedBoard, _boards, (val) => setState(() => _selectedBoard = val!)),
                    SizedBox(height: 20),
                    _buildLabel('Class'),
                    SizedBox(height: 8),
                    _buildDropdown(_selectedClass, _classes, (val) => setState(() => _selectedClass = val!)),
                    SizedBox(height: 20),
                    _buildLabel('Preferred Language'),
                    SizedBox(height: 8),
                    _buildDropdown(_selectedLanguage, _languages, (val) => setState(() => _selectedLanguage = val!)),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appTextPrimary));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.appSurface)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.appSurface)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.appSurface)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged),
      ),
    );
  }
}
