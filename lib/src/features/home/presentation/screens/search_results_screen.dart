import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.toLowerCase();

    // Replicate data sources
    final allCourses = [
      {'title': 'Python', 'icon': Icons.data_object, 'color': const Color(0xFFF59E0B)},
      {'title': 'C Language', 'icon': Icons.terminal, 'color': const Color(0xFF10B981)},
      {'title': 'Data Structs', 'icon': Icons.account_tree, 'color': const Color(0xFFEF4444)},
      {'title': 'SQL', 'icon': Icons.storage, 'color': const Color(0xFF3B82F6)},
    ];

    final allTopics = [
      {'title': 'Arrays and Strings', 'duration': '15 mins', 'subject': 'Java'},
      {'title': 'For and While Loops', 'duration': '10 mins', 'subject': 'Python'},
      {'title': 'Pointers Basics', 'duration': '20 mins', 'subject': 'C'},
    ];

    final matchedCourses = allCourses.where((course) => (course['title'] as String).toLowerCase().contains(lowerQuery)).toList();
    final matchedTopics = allTopics.where((topic) {
      return (topic['title'] as String).toLowerCase().contains(lowerQuery) || (topic['subject'] as String).toLowerCase().contains(lowerQuery);
    }).toList();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Search: "$query"',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (matchedCourses.isEmpty && matchedTopics.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: context.appTextSecondary.withValues(alpha: 0.5)),
                          SizedBox(height: 16),
                          Text(
                            'No results found for "$query"',
                            style: TextStyle(fontSize: 18, color: context.appTextSecondary, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search to find what you are looking for.',
                            style: TextStyle(color: context.appTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (matchedCourses.isNotEmpty) ...[
                  Text(
                    'Courses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: matchedCourses.length,
                    itemBuilder: (context, index) {
                      final course = matchedCourses[index];
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (course['color'] as Color).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(course['icon'] as IconData, color: course['color'] as Color, size: 28),
                            ),
                            SizedBox(height: 12),
                            Text(
                              course['title'] as String,
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32),
                ],

                if (matchedTopics.isNotEmpty) ...[
                  Text(
                    'Topics & Lessons',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matchedTopics.length,
                    itemBuilder: (context, index) {
                      final topic = matchedTopics[index];
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
                              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.play_arrow_rounded, color: AppTheme.primary),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic['title']!,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${topic['subject']} • ${topic['duration']}',
                                    style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: context.appTextSecondary),
                          ],
                        ),
                      );
                    },
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
