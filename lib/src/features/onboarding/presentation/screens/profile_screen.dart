import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'my_notes_screen.dart';
import 'payment_history_screen.dart';
import 'settings_screen.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;
  String? _selectedCourseName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final user = await _firestoreService.getUserProfile(uid);
      final selection = await _firestoreService.getStudentSelection(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _selectedCourseName = selection?['courseName']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeCourse() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final courses = await _firestoreService.streamCourses().first;
    if (!mounted) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Select your course'),
        children: [
          for (final course in courses)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, course.id),
              child: Row(
                children: [
                  Icon(Icons.school, color: AppTheme.primary, size: 22),
                  SizedBox(width: 12),
                  Text(course.title),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null) return;
    final course = courses.firstWhere((c) => c.id == selected);
    await _firestoreService.selectCourse(uid, course.id, course.title);
    if (mounted) {
      setState(() => _selectedCourseName = course.title);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course set to ${course.title}.')),
      );
    }
  }

  void _launchUpgrade() {
    context.push('/payment');
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Student';
    final subtitle = _user != null ? '${_user!.studentClass} • ${_user!.board} Board' : 'Complete your profile';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Profile', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: context.appSurface,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(displayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 14, color: context.appTextSecondary)),
            SizedBox(height: 32),

            // Stats Row
            Row(
              children: [
                _buildStatCard('12', 'Day Streak', Icons.local_fire_department, Colors.orange),
                SizedBox(width: 16),
                _buildStatCard('45', 'Lessons', Icons.play_lesson, AppTheme.primary),
              ],
            ),
            SizedBox(height: 32),

            // Premium Banner
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Go Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Unlock all PYQs & AI Chat', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _launchUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appSurface,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Upgrade'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Options
            _buildOptionTile('Edit Profile', Icons.person_outline, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => _loadProfile());
            }),
            _buildOptionTile(
              _selectedCourseName == null ? 'Select Course' : 'My Course: $_selectedCourseName',
              Icons.school_outlined,
              onTap: _changeCourse,
            ),
            _buildOptionTile('My Notes', Icons.notes, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyNotesScreen()));
            }),
            _buildOptionTile('Payment History', Icons.receipt_long, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
            }),
            _buildOptionTile('Settings', Icons.settings_outlined, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _buildOptionTile('Log Out', Icons.logout, isDestructive: true, onTap: _logout),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            Text(label, style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withAlpha(25) : context.appSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primary),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : context.appTextPrimary)),
      trailing: Icon(Icons.chevron_right, color: context.appTextSecondary),
      onTap: onTap,
    );
  }
}
