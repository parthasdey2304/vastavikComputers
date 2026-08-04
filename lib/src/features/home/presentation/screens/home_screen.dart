import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../practice/presentation/screens/practice_screen.dart';
import '../../../ai_chat/presentation/screens/chat_screen.dart';
import '../../../onboarding/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/course.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../learning_path/presentation/screens/learning_path_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

final _popularTopicsStreamProvider =
    StreamProvider<List<PopularTopicModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamPopularTopics();
});

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final apkUrl = await UpdateService.checkForUpdate();
    if (apkUrl != null && mounted) {
      _showUpdateDialog(apkUrl);
    }
  }

  void _showUpdateDialog(String apkUrl) {
    bool isDownloading = false;
    double progress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Update Available!'),
              content: isDownloading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Downloading update...'),
                        SizedBox(height: 16),
                        LinearProgressIndicator(value: progress),
                        SizedBox(height: 8),
                        Text('${(progress * 100).toStringAsFixed(1)}%'),
                      ],
                    )
                  : Text('A new version of vastavikComputers is available. Would you like to install it now?'),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Later'),
                  ),
                if (!isDownloading)
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() {
                        isDownloading = true;
                      });
                      await UpdateService.downloadAndInstall(apkUrl, (p) {
                        setDialogState(() {
                          progress = p;
                        });
                      });
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Update Now'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const LearningPathScreen(),
          const PracticeScreen(),
          const ChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: ResponsiveWrapper(
        child: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('Continue Learning', 'View All'),
                SizedBox(height: 16),
                _buildContinueLearningCard(),
                SizedBox(height: 32),
                _buildSectionTitle('Promotions', 'See All'),
                SizedBox(height: 16),
                _buildPromoBanners(),
                SizedBox(height: 32),
                _buildSectionTitle('More Practice', ''),
                SizedBox(height: 16),
                _buildPyqEntryCard(context),
                SizedBox(height: 32),
                _buildSectionTitle('Course Catalog', 'Explore'),
                SizedBox(height: 16),
                _buildCourseCatalog(),
                SizedBox(height: 32),
                _buildSectionTitle('Popular Topics', ''),
                SizedBox(height: 16),
                _buildPopularTopics(),
                SizedBox(height: 32),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userProfile = ref.watch(userProfileStreamProvider).value;
    final firstName = userProfile?['name']?.toString().split(' ').first ?? 'Student';

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ready to write some code?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: context.appSurface,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    context.push('/search?q=${Uri.encodeComponent(val.trim())}');
                    _searchController.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search courses, topics...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: context.appTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
          ),
        ),
        if (action.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              action,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueLearningCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF6366F1)], // Indigo shades
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.code, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text(
                'Java Programming',
                style: TextStyle(
                  color: context.appSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Object-Oriented Programming (OOP) Concepts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.appSurface,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(AppTheme.accent), // Teal
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/lesson'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanners() {
    final fs = ref.read(firestoreServiceProvider);
    return FutureBuilder<List<BannerModel>>(
      future: fs.streamBanners().first,
      builder: (context, snapshot) {
        final banners = snapshot.data ?? [];
        if (banners.isEmpty) return SizedBox.shrink();
        final banner = banners.first; // show first promo on home
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Color(banner.color),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner.title,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              if (banner.subtitle.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(banner.subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPyqEntryCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/pyq'),
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
            Icon(Icons.article_outlined, color: AppTheme.primary, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Past Year Questions (PYQ)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.appTextPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Practice previous board exam papers',
                    style: TextStyle(fontSize: 12, color: context.appTextSecondary),
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

  IconData _resolveCourseIcon(String name) {
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

  /// Saves the student's course choice (Img 4) and jumps to the Learn tab.
  void _openCourse(CourseModel course) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.read(firestoreServiceProvider).selectCourse(uid, course.id, course.title);
    }
    ref.read(selectedCourseIdProvider.notifier).state = course.id;
    setState(() => _selectedIndex = 1);
  }

  Widget _buildCourseCatalog() {
    final coursesAsync = ref.watch(coursesStreamProvider);
    const cardHeight = 150.0;
    return coursesAsync.when(
      loading: () => SizedBox(
        height: cardHeight,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => SizedBox(
        height: cardHeight,
        child: Center(
          child: Text('Could not load catalog.',
              style: TextStyle(color: context.appTextSecondary)),
        ),
      ),
      data: (courses) {
        final catalog = courses.where((c) => c.catalogEnabled).toList();
        if (catalog.isEmpty) {
          return SizedBox(
            height: cardHeight,
            child: Center(
              child: Text('No courses yet.',
                  style: TextStyle(color: context.appTextSecondary)),
            ),
          );
        }
        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: catalog.length,
            itemBuilder: (context, index) {
              final course = catalog[index];
              return InkWell(
                onTap: () => _openCourse(course),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _resolveCourseIcon(course.iconName),
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularTopics() {
    final topicsAsync = ref.watch(_popularTopicsStreamProvider);
    return topicsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Could not load topics.',
              style: TextStyle(color: context.appTextSecondary)),
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return SizedBox.shrink();
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appSurface),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.appTextPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          [topic.subject, topic.duration]
                              .where((s) => s.isNotEmpty)
                              .join(' • '),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.appTextSecondary),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.map_rounded, 'Learn'),
              _buildNavItem(2, Icons.assignment_rounded, 'Practice'),
              _buildNavItem(3, Icons.smart_toy_rounded, 'AI Chat'),
              _buildNavItem(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : context.appTextSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
