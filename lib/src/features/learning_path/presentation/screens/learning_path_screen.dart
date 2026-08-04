import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/course.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

final coursesStreamProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamCourses();
});

/// Course chosen by the student (also persisted to `studentSelections`).
final selectedCourseIdProvider = StateProvider<String?>((ref) => null);

/// Live student selection (course + visited parts) for the Learn path.
final studentSelectionStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).streamStudentSelection(uid);
});

/// Zig-zag learning path driven entirely by Firestore:
/// courses → parts → subparts → lessons (with YouTube URLs).
class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  IconData _resolveIcon(String name) {
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

  /// Hydrates the in-memory selection from Firestore the first time.
  void _hydrateSelection(WidgetRef ref) {
    final current = ref.read(selectedCourseIdProvider);
    if (current != null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ref.read(firestoreServiceProvider).getStudentSelection(uid).then((sel) {
      final storedId = sel?['courseId']?.toString();
      if (storedId != null && storedId.isNotEmpty) {
        ref.read(selectedCourseIdProvider.notifier).state = storedId;
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _hydrateSelection(ref);
    final coursesAsync = ref.watch(coursesStreamProvider);
    final selectedCourseId = ref.watch(selectedCourseIdProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Learning Path',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: coursesAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Failed to load courses:\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary)),
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const _EmptyPath();
          }

          final effectiveCourseId =
              selectedCourseId != null && courses.any((c) => c.id == selectedCourseId)
                  ? selectedCourseId
                  : courses.first.id;
          final selectedCourse = courses.firstWhere((c) => c.id == effectiveCourseId);

          return ResponsiveWrapper(
            child: Column(
              children: [
                // Course selector chips
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final isSelected = course.id == effectiveCourseId;
                      return GestureDetector(
                        onTap: () => ref
                            .read(selectedCourseIdProvider.notifier)
                            .state = course.id,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : context.appSurface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _resolveIcon(course.iconName),
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                course.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : context.appTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),

                // Parts as zig-zag path
                Expanded(
                  child: _PartsPathView(course: selectedCourse),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyPath extends StatelessWidget {
  const _EmptyPath();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No courses available yet.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ask your admin to add courses from the Admin Dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartsPathView extends ConsumerWidget {
  final CourseModel course;
  const _PartsPathView({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreServiceProvider);

    return StreamBuilder<List<PartModel>>(
      stream: fs.streamParts(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: TextStyle(color: context.appTextSecondary)),
          );
        }
        final parts = snapshot.data ?? [];
        if (parts.isEmpty) {
          return Center(
            child: Text(
              'No parts added to "${course.title}" yet.',
              style: TextStyle(color: context.appTextSecondary),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return _DuolingoPath(
              course: course,
              parts: parts,
              pathWidth: constraints.maxWidth,
              fs: fs,
              onOpenPart: _openPart,
            );
          },
        );
      },
    );
  }

  void _openPart(
    BuildContext context,
    FirestoreService fs,
    CourseModel course,
    PartModel part,
    Color color,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      fs.markPartVisited(uid, course.id, part.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    part.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<SubpartModel>>(
                    stream: fs.streamSubparts(course.id, part.id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final subparts = snap.data ?? [];
                      if (subparts.isEmpty) {
                        return Center(
                          child: Text('No subparts yet.',
                              style: TextStyle(color: context.appTextSecondary)),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: subparts.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final subpart = subparts[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: context.appSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withAlpha(30),
                                child: Icon(Icons.folder_outlined, color: color),
                              ),
                              title: Text(
                                subpart.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.appTextPrimary),
                              ),
                              childrenPadding:
                                  EdgeInsets.fromLTRB(16, 0, 16, 12),
                              children: [
                                StreamBuilder<List<LessonModel>>(
                                  stream: fs.streamLessons(
                                      course.id, part.id, subpart.id),
                                  builder: (context, lessonSnap) {
                                    if (lessonSnap.connectionState ==
                                        ConnectionState.waiting) {
                                      return Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                      );
                                    }
                                    final lessons = lessonSnap.data ?? [];
                                    if (lessons.isEmpty) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text('No lessons yet.',
                                              style: TextStyle(
                                                  color:
                                                      context.appTextSecondary)),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: lessons
                                          .map(
                                            (lesson) => ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(
                                                  Icons.play_circle_fill,
                                                  color: AppTheme.primary),
                                              title: Text(lesson.title),
                                              subtitle: lesson.duration.isNotEmpty
                                                  ? Text(lesson.duration,
                                                      style: TextStyle(
                                                          fontSize: 12))
                                                  : null,
                                              trailing: Icon(
                                                  Icons.chevron_right,
                                                  color:
                                                      context.appTextSecondary),
                                              onTap: () {
                                                Navigator.pop(context);
                                                context.push(
                                                  '/lesson-detail',
                                                  extra: lesson.toNavigationMap(),
                                                );
                                              },
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Duolingo-style winding path. Nodes are positioned along a snake pattern and
/// connected with curved lines drawn by [_PathPainter].
class _DuolingoPath extends ConsumerWidget {
  final CourseModel course;
  final List<PartModel> parts;
  final double pathWidth;
  final FirestoreService fs;
  final void Function(BuildContext, FirestoreService, CourseModel, PartModel, Color)
      onOpenPart;

  const _DuolingoPath({
    required this.course,
    required this.parts,
    required this.pathWidth,
    required this.fs,
    required this.onOpenPart,
  });

  static const double _rowHeight = 138;
  static const double _circleSize = 62;
  // Node box width: circle + room for a 2-line label without overflowing.
  static const double _nodeBoxWidth = 120;
  // Snake offsets: 0.5 center, 0.22 left, 0.78 right, repeating.
  static const List<double> _offsets = [0.5, 0.22, 0.78, 0.5, 0.22, 0.78];

  Offset _center(int index) {
    final x = pathWidth * _offsets[index % _offsets.length];
    final y = index * _rowHeight + 44;
    return Offset(x, y);
  }

  int _firstUnlocked(List<PartModel> list, Set<String> visited) {
    for (var i = 0; i < list.length; i++) {
      if (!visited.contains(list[i].id)) return i;
    }
    return list.isEmpty ? 0 : list.length - 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppTheme.primary; // brand color, never red/erratic
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final visited = <String>{};
    bool isLoading = false;
    bool hasError = false;

    if (uid != null) {
      final selectionAsync = ref.watch(studentSelectionStreamProvider(uid));
      isLoading = selectionAsync.isLoading;
      hasError = selectionAsync.hasError;
      final selection = selectionAsync.value;
      visited.addAll(FirestoreService.visitedPartIdsForCourse(selection, course.id));
    }

    final totalHeight =
        (parts.length + 2) * _rowHeight; // one row for trophy, one for header
    final firstUnlocked = _firstUnlocked(parts, visited);
    final progress = visited.length;

    return Column(
      children: [
        _PathToolbar(
          loading: isLoading,
          hasError: hasError,
          courseId: course.id,
          courseTitle: course.title,
          progressLabel:
              '$progress / ${parts.length} completed',
          buttonLabel: visited.isEmpty ? 'Start Learning' : 'Continue Learning',
          onButton: firstUnlocked < parts.length
              ? () => onOpenPart(
                    context,
                    fs,
                    course,
                    parts[firstUnlocked],
                    color,
                  )
              : null,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // Connector lines behind the nodes
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PathPainter(
                        points: [
                          for (var i = 0; i < parts.length; i++) _center(i),
                        ],
                        color: color,
                        visitedCount: visited.length,
                      ),
                    ),
                  ),
                  for (var i = 0; i < parts.length; i++)
                    Positioned(
                      left: _center(i).dx - _nodeBoxWidth / 2,
                      top: _center(i).dy - _circleSize / 2,
                      width: _nodeBoxWidth,
                      child: _PathNode(
                        index: i,
                        title: parts[i].title,
                        color: color,
                        isVisited: visited.contains(parts[i].id),
                        isNext: !visited.contains(parts[i].id) &&
                            (i == 0 || visited.contains(parts[i - 1].id)),
                        onTap: () => onOpenPart(
                          context,
                          fs,
                          course,
                          parts[i],
                          color,
                        ),
                      ),
                    ),
                  // Trophy end node
                  Positioned(
                    left: _center(parts.length).dx - _nodeBoxWidth / 2,
                    top: _center(parts.length).dy - _circleSize / 2,
                    width: _nodeBoxWidth,
                    child: _TrophyNode(
                      completed: visited.length >= parts.length,
                    ),
                  ),
                  // Course title header (below the trophy)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (parts.length + 1) * _rowHeight + 8,
                    child: Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${course.title} • Complete the path!',
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Loader + progress + "Continue Learning" button + restart + info.
class _PathToolbar extends StatelessWidget {
  final bool loading;
  final bool hasError;
  final String courseId;
  final String courseTitle;
  final String progressLabel;
  final String buttonLabel;
  final VoidCallback? onButton;

  const _PathToolbar({
    required this.loading,
    required this.hasError,
    required this.courseId,
    required this.courseTitle,
    required this.progressLabel,
    required this.buttonLabel,
    required this.onButton,
  });

  Future<void> _confirmRestart(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restart $courseTitle?'),
        content: Text(
            'This will reset all your progress for this course. You will start from the beginning.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Restart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      await FirestoreService().restartCourse(uid, courseId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$courseTitle restarted from the beginning.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progressLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
              if (onButton != null)
                FilledButton.icon(
                  onPressed: onButton,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(buttonLabel),
                ),
              if (onButton != null) SizedBox(width: 8),
              IconButton(
                tooltip: 'Restart $courseTitle',
                onPressed: () => _confirmRestart(context),
                icon: Icon(Icons.restart_alt, color: context.appTextSecondary),
              ),
            ],
          ),
          // Info banner explaining the path + drag-drop ordering
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Work through each part in order to unlock the next one. '
                    'Complete every part to finish this path. '
                    'Your progress is saved automatically to your account.',
                    style: TextStyle(fontSize: 12, color: context.appTextPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (loading) ...[
            SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (hasError) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Progress sync failed. Showing path anyway.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final int index;
  final String title;
  final Color color;
  final bool isVisited;
  final bool isNext;
  final VoidCallback onTap;

  const _PathNode({
    required this.index,
    required this.title,
    required this.color,
    required this.isVisited,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _DuolingoPath._circleSize,
            height: _DuolingoPath._circleSize,
            decoration: BoxDecoration(
              gradient: (isVisited || isNext)
                  ? const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (isVisited || isNext) ? null : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: isNext
                  ? Border.all(color: Colors.white, width: 4)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (isVisited || isNext ? AppTheme.primary : Colors.grey)
                      .withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isVisited
                  ? Icon(Icons.check, color: Colors.white, size: 28)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isNext ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyNode extends StatelessWidget {
  final bool completed;
  const _TrophyNode({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _DuolingoPath._circleSize,
          height: _DuolingoPath._circleSize,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFFF59E0B) : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x22F59E0B), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Icon(
            completed ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: completed ? Colors.white : Colors.grey.shade400,
            size: 30,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          completed ? 'Path Complete!' : 'End',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final int visitedCount;

  const _PathPainter({
    required this.points,
    required this.color,
    required this.visitedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Underlay trail
    final trail = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    _drawConnections(canvas, trail);

    // Visited portion (brand colored)
    if (visitedCount > 0) {
      final visitedPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      final endIndex = visitedCount.clamp(1, points.length);
      _drawConnections(canvas, visitedPaint, endIndex: endIndex);
    }
  }

  void _drawConnections(Canvas canvas, Paint paint, {int? endIndex}) {
    final count = endIndex ?? points.length;
    for (var i = 0; i < count - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final midY = (p1.dy + p2.dy) / 2;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.visitedCount != visitedCount;
}
