import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/models/course.dart';
import '../../../../core/models/subscription_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';

/// Converts an icon-name string stored in Firestore into a Flutter [IconData].
IconData resolveCourseIcon(String name) {
  switch (name) {
    case 'data_object':
      return Icons.data_object;
    case 'terminal':
      return Icons.terminal;
    case 'account_tree':
      return Icons.account_tree;
    case 'storage':
      return Icons.storage;
    case 'language':
      return Icons.language;
    case 'functions':
      return Icons.functions;
    case 'loop':
      return Icons.loop;
    case 'category':
      return Icons.category;
    default:
      return Icons.code;
  }
}

/// Reusable labelled text field used throughout the admin forms.
class AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const AdminField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: context.appSurface,
        ),
      ),
    );
  }
}

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  static const String _adminUsername = 'admin@vastavik.bdsm';
  static const String _adminPassword = 'MeriMaaKaaBharosa';
  static bool _adminUnlocked = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loginError = false;
  bool _loginAttempting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username == _adminUsername && password == _adminPassword) {
      setState(() {
        _adminUnlocked = true;
        _loginError = false;
        _loginAttempting = false;
      });
    } else {
      setState(() {
        _loginError = true;
        _loginAttempting = false;
      });
    }
  }

  Widget _buildLoginGate() {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(
          'Admin Access',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.appTextPrimary),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Admin Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter your admin credentials to manage the platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      enabled: !_loginAttempting,
                      onSubmitted: (_) => _attemptLogin(),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'admin@vastavik.bdsm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: context.appSurface,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      enabled: !_loginAttempting,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) => _attemptLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: context.appSurface,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    if (_loginError) ...[
                      SizedBox(height: 12),
                      Text(
                        'Invalid username or password. Please try again.',
                        style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                      ),
                    ],
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loginAttempting
                          ? null
                          : () {
                              setState(() => _loginAttempting = true);
                              _attemptLogin();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_adminUnlocked) {
      return _buildLoginGate();
    }

    final fs = ref.watch(firestoreServiceProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.appTextPrimary),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: 'Lock Admin',
            icon: Icon(Icons.logout, color: context.appTextPrimary),
            onPressed: () {
              _usernameController.clear();
              _passwordController.clear();
              setState(() {
                _adminUnlocked = false;
                _loginError = false;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              SizedBox(height: 24),
              _LiveStatCards(fs: fs),
              SizedBox(height: 32),
              Text(
                'Content Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'Manage Courses & Lessons',
                subtitle: 'Create courses, parts, subparts and attach YouTube unlisted lessons.',
                icon: Icons.ondemand_video,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _CoursesManagerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Manage Question Papers',
                subtitle: 'Add MCQ question papers and coding challenges.',
                icon: Icons.quiz,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _QuestionPapersManagerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Manage Banners',
                subtitle: 'Promotional banners shown inside the app.',
                icon: Icons.view_carousel,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _BannersManagerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Upload PDFs',
                subtitle: 'Attach PYQ PDF papers, notes and study material to question papers.',
                icon: Icons.picture_as_pdf,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _PdfManagerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Popular Topics',
                subtitle: 'Curate the topics shown on the home screen.',
                icon: Icons.whatshot,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _PopularTopicsManagerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Subscriptions & Payments',
                subtitle: 'Every student, mandate status, next billing date and transactions.',
                icon: Icons.payments_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _SubscriptionsManagerScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Live dashboard stats
// =====================================================================

class _LiveStatCards extends StatelessWidget {
  final FirestoreService fs;
  const _LiveStatCards({required this.fs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AsyncStatCard(
                title: 'Total Users',
                icon: Icons.people,
                future: fs.getTotalUserCount(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _AsyncStatCard(
                title: 'Question Papers',
                icon: Icons.quiz,
                future: fs.getQuestionPaperCount(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AsyncStatCard(
                title: 'Banners',
                icon: Icons.view_carousel,
                future: fs.getBannerCount(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Revenue (INR)',
                value: 'Phase 2',
                icon: Icons.currency_rupee,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AsyncStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> future;
  const _AsyncStatCard({required this.title, required this.icon, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snap) {
        final value = snap.hasData ? snap.data.toString() : 'â€¦';
        return _StatCard(title: title, value: value, icon: icon);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Courses & Lessons Manager
// =====================================================================

class _CoursesManagerScreen extends ConsumerWidget {
  const _CoursesManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Courses & Lessons',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Course', style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _CourseFormDialog(),
        ),
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: fs.streamCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const _EmptyState(
              icon: Icons.school,
              message: 'No courses yet. Tap "Add Course" to create the first one.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, size: 18, color: context.appTextSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hold and drag the handle to reorder courses. Changes save to Firestore automatically.',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: courses.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final reordered = [...courses];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    // Persist new positions to Firestore
                    for (var i = 0; i < reordered.length; i++) {
                      await fs.updateCourseOrder(reordered[i].id, i);
                    }
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Padding(
                      key: ValueKey(course.id),
                      padding: EdgeInsets.only(bottom: 12),
                      child: _CourseAdminCard(course: course),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseAdminCard extends ConsumerWidget {
  final CourseModel course;
  const _CourseAdminCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(course.color).withAlpha(30),
          child: Icon(resolveCourseIcon(course.iconName), color: Color(course.color)),
        ),
        title: Text(course.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
        subtitle: Text(course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _PartFormDialog(courseId: course.id),
                ),
                icon: Icon(Icons.add, size: 18),
                label: Text('Add Part'),
              ),              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                      context, 'Delete course "${course.title}" and all its content?');
                  if (confirmed) await fs.deleteCourse(course.id);
                },
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: Text('Delete Course', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          StreamBuilder<List<PartModel>>(
            stream: fs.streamParts(course.id),
            builder: (context, snap) {
              final parts = snap.data ?? [];
              if (parts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No parts yet.', style: TextStyle(color: context.appTextSecondary)),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.drag_indicator, size: 14, color: context.appTextSecondary),
                      SizedBox(width: 6),
                      Text('Drag to reorder parts',
                          style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                    ],
                  ),
                  SizedBox(height: 4),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: parts.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final reordered = [...parts];
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      for (var i = 0; i < reordered.length; i++) {
                        await fs.updatePartOrder(course.id, reordered[i].id, i);
                      }
                    },
                    proxyDecorator: (child, index, animation) => Material(
                      color: Colors.transparent,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, index) {
                      final part = parts[index];
                      return Padding(
                        key: ValueKey(part.id),
                        padding: EdgeInsets.only(bottom: 8),
                        child: _PartAdminTile(courseId: course.id, part: part),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PartAdminTile extends ConsumerWidget {
  final String courseId;
  final PartModel part;
  const _PartAdminTile({required this.courseId, required this.part});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        title: Text(part.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary)),
        childrenPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _SubpartFormDialog(courseId: courseId, partId: part.id),
                ),
                icon: Icon(Icons.add, size: 18),
                label: Text('Add Subpart'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed =
                      await _confirmDelete(context, 'Delete part "${part.title}"?');
                  if (confirmed) await fs.deletePart(courseId, part.id);
                },
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          StreamBuilder<List<SubpartModel>>(
            stream: fs.streamSubparts(courseId, part.id),
            builder: (context, snap) {
              final subparts = snap.data ?? [];
              if (subparts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No subparts.', style: TextStyle(color: context.appTextSecondary)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.drag_indicator, size: 14, color: context.appTextSecondary),
                      SizedBox(width: 6),
                      Text('Drag to reorder subparts',
                          style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                    ],
                  ),
                  SizedBox(height: 4),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subparts.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final reordered = [...subparts];
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      for (var i = 0; i < reordered.length; i++) {
                        await fs.updateSubpartOrder(
                            courseId, part.id, reordered[i].id, i);
                      }
                    },
                    proxyDecorator: (child, index, animation) => Material(
                      color: Colors.transparent,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, index) {
                      final sp = subparts[index];
                      return Padding(
                        key: ValueKey(sp.id),
                        padding: EdgeInsets.only(bottom: 8),
                        child: _SubpartAdminTile(
                          courseId: courseId,
                          partId: part.id,
                          subpart: sp,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubpartAdminTile extends ConsumerWidget {
  final String courseId;
  final String partId;
  final SubpartModel subpart;
  const _SubpartAdminTile({
    required this.courseId,
    required this.partId,
    required this.subpart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        title: Text(subpart.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        childrenPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _LessonFormDialog(
                    courseId: courseId,
                    partId: partId,
                    subpartId: subpart.id,
                  ),
                ),
                icon: Icon(Icons.video_call, size: 18),
                label: Text('Add Lesson'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed =
                      await _confirmDelete(context, 'Delete subpart "${subpart.title}"?');
                  if (confirmed) await fs.deleteSubpart(courseId, partId, subpart.id);
                },
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          StreamBuilder<List<LessonModel>>(
            stream: fs.streamLessons(courseId, partId, subpart.id),
            builder: (context, snap) {
              final lessons = snap.data ?? [];
              if (lessons.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No lessons.', style: TextStyle(color: context.appTextSecondary)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.drag_indicator, size: 14, color: context.appTextSecondary),
                      SizedBox(width: 6),
                      Text('Drag to reorder lessons',
                          style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                    ],
                  ),
                  SizedBox(height: 4),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lessons.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final reordered = [...lessons];
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      for (var i = 0; i < reordered.length; i++) {
                        await fs.updateLessonOrder(
                            courseId, partId, subpart.id, reordered[i].id, i);
                      }
                    },
                    proxyDecorator: (child, index, animation) => Material(
                      color: Colors.transparent,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Padding(
                        key: ValueKey(lesson.id),
                        padding: EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.play_circle_outline,
                              color: AppTheme.primary),
                          title: Text(lesson.title),
                          subtitle: Text(
                            lesson.youtubeUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirmed = await _confirmDelete(context,
                                  'Delete lesson "${lesson.title}"?');
                              if (confirmed) {
                                await fs.deleteLesson(
                                    courseId, partId, subpart.id, lesson.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Form Dialogs
// =====================================================================

class _CourseFormDialog extends ConsumerStatefulWidget {
  const _CourseFormDialog();

  @override
  ConsumerState<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends ConsumerState<_CourseFormDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _iconName = 'code';
  final Color _color = AppTheme.primary;
  bool _catalogEnabled = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Course'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminField(controller: _title, label: 'Course Title', hint: 'e.g. Java'),
            AdminField(
                controller: _description, label: 'Description', hint: 'Short description', maxLines: 3),
            DropdownButtonFormField<String>(
              initialValue: _iconName,
              decoration: InputDecoration(labelText: 'Icon'),
              items: kCourseIconOptions
                  .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: (v) => setState(() => _iconName = v ?? 'code'),
            ),
            CheckboxListTile(
              value: _catalogEnabled,
              contentPadding: EdgeInsets.zero,
              title: Text('Show in home catalog'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _catalogEnabled = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  final fs = ref.read(firestoreServiceProvider);
                  await fs.createCourse(
                    CourseModel(
                      id: '',
                      title: _title.text.trim(),
                      description: _description.text.trim(),
                      iconName: _iconName,
                      color: _color.toARGB32(),
                      catalogEnabled: _catalogEnabled,
                    ),
                  );
                  if (mounted) Navigator.pop(context);
                },
          child: _saving
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Create'),
        ),
      ],
    );
  }
}

class _PartFormDialog extends ConsumerStatefulWidget {
  final String courseId;
  const _PartFormDialog({required this.courseId});

  @override
  ConsumerState<_PartFormDialog> createState() => _PartFormDialogState();
}

class _PartFormDialogState extends ConsumerState<_PartFormDialog> {
  final _title = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Part'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminField(controller: _title, label: 'Part Title', hint: 'e.g. Object Oriented Programming'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await ref.read(firestoreServiceProvider).createPart(
                        widget.courseId,
                        PartModel(
                          id: '',
                          title: _title.text.trim(),
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

class _SubpartFormDialog extends ConsumerStatefulWidget {
  final String courseId;
  final String partId;
  const _SubpartFormDialog({
    required this.courseId,
    required this.partId,
  });

  @override
  ConsumerState<_SubpartFormDialog> createState() => _SubpartFormDialogState();
}

class _SubpartFormDialogState extends ConsumerState<_SubpartFormDialog> {
  final _title = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Subpart'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminField(controller: _title, label: 'Subpart Title', hint: 'e.g. Inheritance Basics'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await ref.read(firestoreServiceProvider).createSubpart(
                        widget.courseId,
                        widget.partId,
                        SubpartModel(
                          id: '',
                          title: _title.text.trim(),
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

class _LessonFormDialog extends ConsumerStatefulWidget {
  final String courseId;
  final String partId;
  final String subpartId;
  const _LessonFormDialog({
    required this.courseId,
    required this.partId,
    required this.subpartId,
  });

  @override
  ConsumerState<_LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends ConsumerState<_LessonFormDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _youtubeUrl = TextEditingController();
  final _duration = TextEditingController();
  final _position = TextEditingController(text: '0');
  final _codeSample = TextEditingController();
  final _notes = TextEditingController();
  String _whiteboardImageUrl = '';
  bool _uploadingWhiteboard = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _youtubeUrl.dispose();
    _duration.dispose();
    _position.dispose();
    _codeSample.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickWhiteboardImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploadingWhiteboard = true);
    try {
      final url = await ref.read(storageServiceProvider).uploadBytes(
            bytes: bytes,
            folder: 'lessons',
            fileName: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            mimeType: 'image/png',
          );
      if (!mounted) return;
      setState(() => _whiteboardImageUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Whiteboard upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingWhiteboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Lesson'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminField(controller: _title, label: 'Lesson Title'),
            AdminField(controller: _description, label: 'Description', maxLines: 3),
            AdminField(
              controller: _youtubeUrl,
              label: 'YouTube URL (unlisted)',
              hint: 'https://www.youtube.com/watch?v=xxxx  or  https://youtu.be/xxxx',
            ),
            AdminField(
              controller: _duration,
              label: 'Duration (optional)',
              hint: 'e.g. 12:30',
            ),
            AdminField(
              controller: _position,
              label: 'Start Position (seconds)',
              hint: 'e.g. 120 to start at 2:00',
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: _uploadingWhiteboard
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Uploading whiteboard...'),
                            ],
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: _pickWhiteboardImage,
                          icon: Icon(Icons.image_outlined),
                          label: Text('Upload Whiteboard Image'),
                        ),
                ),
                if (_whiteboardImageUrl.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                ],
              ],
            ),
            if (_whiteboardImageUrl.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Whiteboard attached.',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                  ),
                ),
              ),
            AdminField(controller: _codeSample, label: 'Code Sample (optional)', maxLines: 5),
            AdminField(controller: _notes, label: 'Key Takeaways / Notes (optional)', maxLines: 4),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await ref.read(firestoreServiceProvider).createLesson(
                        widget.courseId,
                        widget.partId,
                        widget.subpartId,
                        LessonModel(
                          id: '',
                          title: _title.text.trim(),
                          description: _description.text.trim(),
                          youtubeUrl: _youtubeUrl.text.trim(),
                          duration: _duration.text.trim(),
                          youtubePositionSec: int.tryParse(_position.text.trim()) ?? 0,
                          whiteboardImageUrl: _whiteboardImageUrl,
                          codeSample: _codeSample.text,
                          notes: _notes.text.trim(),
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

// =====================================================================
// Question Papers Manager
// =====================================================================

class _QuestionPapersManagerScreen extends ConsumerWidget {
  const _QuestionPapersManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Question Papers',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Paper', style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _QuestionPaperFormDialog(),
        ),
      ),
      body: StreamBuilder<List<QuestionPaperModel>>(
        stream: fs.streamQuestionPapers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final papers = snapshot.data ?? [];
          if (papers.isEmpty) {
            return const _EmptyState(
              icon: Icons.quiz,
              message: 'No question papers yet. Tap "Add Paper" to create one.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: papers.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final paper = papers[index];
              final isMcq = paper.type == 'mcq';
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          (isMcq ? AppTheme.primary : AppTheme.accent).withAlpha(30),
                      child: Icon(isMcq ? Icons.list_alt : Icons.code,
                          color: isMcq ? AppTheme.primary : AppTheme.accent),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(paper.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                          SizedBox(height: 4),
                          Text(
                            '${paper.subject} â€¢ ${isMcq ? 'MCQ' : 'Coding'} â€¢ ${paper.questions.length} questions â€¢ ${paper.timeLimitMinutes} min',
                            style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirmed =
                            await _confirmDelete(context, 'Delete paper "${paper.title}"?');
                        if (confirmed) await fs.deleteQuestionPaper(paper.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionPaperFormDialog extends ConsumerStatefulWidget {
  const _QuestionPaperFormDialog();

  @override
  ConsumerState<_QuestionPaperFormDialog> createState() =>
      _QuestionPaperFormDialogState();
}

class _QuestionPaperFormDialogState extends ConsumerState<_QuestionPaperFormDialog> {
  final _title = TextEditingController();
  final _subject = TextEditingController(text: 'Java');
  final _timeLimit = TextEditingController(text: '30');
  String _type = 'mcq';
  final List<_QuestionDraft> _questions = [];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _timeLimit.dispose();
    super.dispose();
  }

  Future<void> _addQuestion() async {
    final draft = await showDialog<_QuestionDraft>(
      context: context,
      builder: (_) => _QuestionEditDialog(type: _type),
    );
    if (draft != null) setState(() => _questions.add(draft));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Question Paper'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminField(controller: _title, label: 'Paper Title'),
              AdminField(controller: _subject, label: 'Subject', hint: 'Java / Python / ...'),
              AdminField(
                  controller: _timeLimit,
                  label: 'Time Limit (minutes)',
                  keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: 'Paper Type'),
                items: const [
                  DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                  DropdownMenuItem(value: 'coding', child: Text('Coding Challenge')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'mcq'),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Questions (${_questions.length})',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: Icon(Icons.add),
                    label: Text('Add Question'),
                  ),
                ],
              ),
              ..._questions.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${entry.key + 1}.'),
                      title: Text(
                        _type == 'mcq'
                            ? (entry.value.question ?? '')
                            : (entry.value.problemStatement ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _questions.removeAt(entry.key)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  final fs = ref.read(firestoreServiceProvider);
                  final questionMaps = _type == 'mcq'
                      ? _questions
                          .map((q) => {
                                'type': 'mcq',
                                'question': q.question ?? '',
                                'options': q.options ?? const <String>[],
                                'correctIndex': q.correctIndex ?? 0,
                              })
                          .toList()
                      : _questions
                          .map((q) => {
                                'type': 'coding',
                                'problemStatement': q.problemStatement ?? '',
                                'starterCode': q.starterCode ?? '',
                                'expectedOutput': q.expectedOutput ?? '',
                              })
                          .toList();
                  await fs.createQuestionPaper(
                    QuestionPaperModel(
                      id: '',
                      title: _title.text.trim(),
                      type: _type,
                      subject: _subject.text.trim().isEmpty
                          ? 'General'
                          : _subject.text.trim(),
                      timeLimitMinutes: int.tryParse(_timeLimit.text.trim()) ?? 30,
                      questions: questionMaps,
                    ),
                  );
                  if (mounted) Navigator.pop(context);
                },
          child: _saving
              ? SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Create'),
        ),
      ],
    );
  }
}

class _QuestionDraft {
  // MCQ
  final String? question;
  final List<String>? options;
  final int? correctIndex;
  // Coding
  final String? problemStatement;
  final String? starterCode;
  final String? expectedOutput;

  _QuestionDraft.mcq({
    required this.question,
    required this.options,
    required this.correctIndex,
  })  : problemStatement = null,
        starterCode = null,
        expectedOutput = null;

  _QuestionDraft.coding({
    required this.problemStatement,
    this.starterCode,
    this.expectedOutput,
  })  : question = null,
        options = null,
        correctIndex = null;
}

class _QuestionEditDialog extends StatefulWidget {
  final String type;
  const _QuestionEditDialog({required this.type});

  @override
  State<_QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<_QuestionEditDialog> {
  final _question = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  final _problem = TextEditingController();
  final _starter = TextEditingController();
  final _expected = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _problem.dispose();
    _starter.dispose();
    _expected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMcq = widget.type == 'mcq';
    return AlertDialog(
      title: Text(isMcq ? 'New MCQ' : 'New Coding Challenge'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: isMcq ? _buildMcqForm() : _buildCodingForm(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: Text('Add')),
      ],
    );
  }

  Widget _buildMcqForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminField(controller: _question, label: 'Question', maxLines: 3),
        ...List.generate(
          4,
          (i) => AdminField(
            controller: _optionControllers[i],
            label: 'Option ${String.fromCharCode(65 + i)}',
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: _correctIndex,
          decoration: InputDecoration(labelText: 'Correct option'),
          items: List.generate(
            4,
            (i) => DropdownMenuItem(
                value: i, child: Text('Option ${String.fromCharCode(65 + i)}')),
          ),
          onChanged: (v) => setState(() => _correctIndex = v ?? 0),
        ),
      ],
    );
  }

  Widget _buildCodingForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminField(controller: _problem, label: 'Problem Statement', maxLines: 5),
        AdminField(controller: _starter, label: 'Starter Code (optional)', maxLines: 5),
        AdminField(controller: _expected, label: 'Expected Output (optional)', maxLines: 3),
      ],
    );
  }

  void _submit() {
    if (widget.type == 'mcq') {
      if (_question.text.trim().isEmpty) return;
      Navigator.pop(
        context,
        _QuestionDraft.mcq(
          question: _question.text.trim(),
          options: _optionControllers.map((c) => c.text.trim()).toList(),
          correctIndex: _correctIndex,
        ),
      );
    } else {
      if (_problem.text.trim().isEmpty) return;
      Navigator.pop(
        context,
        _QuestionDraft.coding(
          problemStatement: _problem.text.trim(),
          starterCode: _starter.text,
          expectedOutput: _expected.text.trim(),
        ),
      );
    }
  }
}

// =====================================================================
// PDF Manager (files go to Firebase Storage, metadata to Firestore)
// =====================================================================

class _PdfManagerScreen extends ConsumerWidget {
  const _PdfManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Upload PDFs',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: StreamBuilder<List<QuestionPaperModel>>(
        stream: fs.streamQuestionPapers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final papers = snapshot.data ?? [];
          if (papers.isEmpty) {
            return const _EmptyState(
              icon: Icons.picture_as_pdf,
              message: 'No question papers yet. Create one in "Manage Question Papers" first, then attach PDFs to it.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: papers.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final paper = papers[index];
              return _PdfPaperCard(paper: paper);
            },
          );
        },
      ),
    );
  }
}

class _PdfPaperCard extends ConsumerStatefulWidget {
  final QuestionPaperModel paper;
  const _PdfPaperCard({required this.paper});

  @override
  ConsumerState<_PdfPaperCard> createState() => _PdfPaperCardState();
}

class _PdfPaperCardState extends ConsumerState<_PdfPaperCard> {
  bool _uploading = false;

  Future<void> _uploadPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploading = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final pdfUrl = await storage.uploadBytes(
        bytes: bytes,
        folder: 'papers/${widget.paper.id}',
        fileName: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        mimeType: 'application/pdf',
      );
      await ref.read(firestoreServiceProvider).addPaperAttachment(
            widget.paper.id,
            pdfUrl: pdfUrl,
            fileName: file.name,
            sizeBytes: bytes.length,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${file.name}" uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePdf(Map<String, dynamic> attachment) async {
    final id = attachment['id'] as String? ?? '';
    final fileName = attachment['fileName']?.toString() ?? 'PDF';
    final confirmed =
        await _confirmDelete(context, 'Delete "$fileName"?');
    if (!confirmed) return;
    await ref.read(storageServiceProvider)
        .deleteByUrl(attachment['pdfUrl']?.toString() ?? '');
    await ref.read(firestoreServiceProvider)
        .deletePaperAttachment(widget.paper.id, id);
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(firestoreServiceProvider);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withAlpha(20),
                child: Icon(Icons.picture_as_pdf, color: AppTheme.primary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.paper.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: _uploading ? null : _uploadPdf,
                icon: _uploading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.upload_file, size: 18),
                label: Text(_uploading ? 'Uploadingâ€¦' : 'Upload PDF'),
              ),
            ],
          ),
          SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: fs.streamPaperAttachments(widget.paper.id),
            builder: (context, snap) {
              final attachments = snap.data ?? [];
              if (attachments.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No PDFs attached yet.',
                      style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                );
              }
              return Column(
                children: attachments.map((att) {
                  final fileName = att['fileName']?.toString() ?? 'document.pdf';
                  final sizeBytes = (att['sizeBytes'] as num?)?.toInt() ?? 0;
                  final sizeLabel = sizeBytes >= 1048576
                      ? '${(sizeBytes / 1048576).toStringAsFixed(1)} MB'
                      : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.description_outlined, color: AppTheme.primary),
                    title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(sizeLabel, style: TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deletePdf(att),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Subscriptions & Payments Manager (Phase 3 admin insights)
// =====================================================================

class _SubscriptionsManagerScreen extends ConsumerWidget {
  const _SubscriptionsManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          elevation: context.isDark ? 0 : 1,
          title: Text('Subscriptions & Payments',
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: context.appTextPrimary),
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: context.appTextSecondary,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentsTab(fs: fs),
            _TransactionsTab(fs: fs),
          ],
        ),
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final FirestoreService fs;
  const _StudentsTab({required this.fs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_adminUsersProvider);
    final subsAsync = ref.watch(_adminSubscriptionsProvider);

    return usersAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load students: $e')),
      data: (users) {
        final subs = subsAsync.value ?? [];
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, _) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['uid']?.toString() ?? '';
            final sub = subs.where((s) => s.uid == uid).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final latest = sub.isNotEmpty ? sub.first : null;

            final isPremium = user['isPremium'] == true;
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (isPremium ? AppTheme.accent : AppTheme.primary)
                            .withAlpha(25),
                        child: Icon(
                          isPremium ? Icons.workspace_premium : Icons.person_outline,
                          color: isPremium ? AppTheme.accent : AppTheme.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name']?.toString() ?? 'Student',
                              style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              user['email']?.toString() ?? '',
                              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? AppTheme.accent.withAlpha(20)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPremium ? 'PREMIUM' : 'FREE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPremium ? AppTheme.accent : context.appTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (latest != null) ...[
                    _infoRow(context, 'Plan', latest.planTitle),
                    _infoRow(context, 'Status', latest.status),
                    _infoRow(
                      context,
                      'Next billing',
                      latest.nextBillingDate != null
                          ? _fmtDate(latest.nextBillingDate!)
                          : 'â€”',
                    ),
                    _infoRow(context, 'Mandate ID', latest.mandateId ?? 'â€”'),
                  ] else
                    _infoRow(context, 'Subscription', 'No mandate yet'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.appTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

class _TransactionsTab extends ConsumerWidget {
  final FirestoreService fs;
  const _TransactionsTab({required this.fs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(_adminTransactionsProvider);
    return txnsAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load transactions: $e')),
      data: (txns) {
        if (txns.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long,
            message: 'No transactions yet.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: txns.length,
          separatorBuilder: (_, _) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final txn = txns[index];
            final success = txn.status == 'success';
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (success ? Colors.green : Colors.red).withAlpha(20),
                    child: Icon(
                      success ? Icons.check_circle : Icons.cancel,
                      color: success ? Colors.green : Colors.red,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(txn.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary)),
                        SizedBox(height: 2),
                        Text(
                          'â‚¹${txn.amount.toStringAsFixed(0)} â€¢ ${_fmtDate(txn.timestamp)} â€¢ ${txn.uid}',
                          style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    txn.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

final _adminUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firestoreServiceProvider).streamAllUsers();
});

final _adminSubscriptionsProvider = StreamProvider<List<SubscriptionModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamAllSubscriptions();
});

final _adminTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamAllTransactions();
});

// =====================================================================
// Popular Topics Manager (home screen, Img 3)
// =====================================================================

class _PopularTopicsManagerScreen extends ConsumerWidget {
  const _PopularTopicsManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Popular Topics',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Topic', style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _PopularTopicFormDialog(),
        ),
      ),
      body: StreamBuilder<List<PopularTopicModel>>(
        stream: fs.streamPopularTopics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            return const _EmptyState(
              icon: Icons.whatshot,
              message: 'No popular topics yet. Tap "Add Topic" to create one.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, size: 18, color: context.appTextSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hold and drag to reorder topics. Changes save automatically.',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: topics.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final reordered = [...topics];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    for (var i = 0; i < reordered.length; i++) {
                      await fs.updatePopularTopicOrder(reordered[i].id, i);
                    }
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Container(
                      key: ValueKey(topic.id),
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withAlpha(20),
                            child: Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topic.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.appTextPrimary)),
                                SizedBox(height: 4),
                                Text(
                                  [topic.subject, topic.duration, topic.courseId]
                                      .where((s) => s.isNotEmpty)
                                      .join(' â€¢ '),
                                  style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await _confirmDelete(
                                  context, 'Delete topic "${topic.title}"?');
                              if (confirmed) await fs.deletePopularTopic(topic.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PopularTopicFormDialog extends ConsumerStatefulWidget {
  const _PopularTopicFormDialog();

  @override
  ConsumerState<_PopularTopicFormDialog> createState() =>
      _PopularTopicFormDialogState();
}

class _PopularTopicFormDialogState extends ConsumerState<_PopularTopicFormDialog> {
  final _title = TextEditingController();
  final _duration = TextEditingController();
  final _subject = TextEditingController();
  final _courseId = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _subject.dispose();
    _courseId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Popular Topic'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminField(controller: _title, label: 'Topic Title', hint: 'e.g. Arrays and Strings'),
            AdminField(controller: _subject, label: 'Subject', hint: 'e.g. Java'),
            AdminField(controller: _duration, label: 'Duration', hint: 'e.g. 15 mins'),
            AdminField(
                controller: _courseId,
                label: 'Course ID (optional)',
                hint: 'Link to a course from the Courses collection'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await ref.read(firestoreServiceProvider).createPopularTopic(
                        PopularTopicModel(
                          id: '',
                          title: _title.text.trim(),
                          subject: _subject.text.trim(),
                          duration: _duration.text.trim(),
                          courseId: _courseId.text.trim(),
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

// =====================================================================
// Banners Manager
// =====================================================================

class _BannersManagerScreen extends ConsumerWidget {
  const _BannersManagerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('Banners',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Banner', style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _BannerFormDialog(),
        ),
      ),
      body: StreamBuilder<List<BannerModel>>(
        stream: fs.streamBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final banners = snapshot.data ?? [];
          if (banners.isEmpty) {
            return const _EmptyState(
              icon: Icons.view_carousel,
              message: 'No banners yet. Tap "Add Banner" to create one.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, size: 18, color: context.appTextSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hold and drag to reorder banners. Changes save automatically.',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: banners.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final reordered = [...banners];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    for (var i = 0; i < reordered.length; i++) {
                      await fs.updateBannerOrder(reordered[i].id, i);
                    }
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20),
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return Container(
                      key: ValueKey(banner.id),
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(banner.color),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: TextStyle(
                                      color: context.appSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (banner.subtitle.isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  Text(
                                    banner.subtitle,
                                    style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 13),
                                  ),
                                ],
                                if (banner.actionLink.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    banner.actionLink,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: () async {
                              final confirmed =
                                  await _confirmDelete(context, 'Delete banner "${banner.title}"?');
                              if (confirmed) await fs.deleteBanner(banner.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BannerFormDialog extends ConsumerStatefulWidget {
  const _BannerFormDialog();

  @override
  ConsumerState<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<_BannerFormDialog> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _actionLink = TextEditingController();
  Color _selectedColor = AppTheme.primary;
  bool _saving = false;

  static const List<Color> _colors = [
    Color(0xFF4F46E5),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _actionLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminField(controller: _title, label: 'Title'),
            AdminField(controller: _subtitle, label: 'Subtitle'),
            AdminField(controller: _actionLink, label: 'Action Link', hint: '/course/... or https://'),
            Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map(
                    (c) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 16,
                        child: _selectedColor == c
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_title.text.trim().isEmpty) return;
                  setState(() => _saving = true);
                  await ref.read(firestoreServiceProvider).createBanner(
                        BannerModel(
                          id: '',
                          title: _title.text.trim(),
                          subtitle: _subtitle.text.trim(),
                          actionLink: _actionLink.text.trim(),
                          color: _selectedColor.toARGB32(),
                        ),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

// =====================================================================
// Shared small widgets
// =====================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm delete'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
