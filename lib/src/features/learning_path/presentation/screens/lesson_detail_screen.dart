import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lessonData;
  const LessonDetailScreen({super.key, required this.lessonData});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background like editor
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.lessonData['title'] ?? 'Lesson', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Video Placeholder
          Container(
            width: double.infinity,
            height: 220,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white30, size: 64),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: const Text('05:24', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
          
          // Header info
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lessonData['title'] ?? 'Object-Oriented Programming (OOP)',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn the fundamentals of classes, objects, and inheritance in Java.',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1), // Indigo
              unselectedLabelColor: Colors.black54,
              indicatorColor: const Color(0xFF6366F1),
              tabs: const [
                Tab(text: 'Code & Notes'),
                Tab(text: 'Whiteboard'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC), // Very light gray/blue background
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCodeAndNotesTab(),
                  _buildWhiteboardTab(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCodeAndNotesTab() {
    const sampleCode = '''class Animal {
  void sound() {
    System.out.println("Bark");
  }
}

class Dog extends Animal {}''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Implementation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E), // Dark code background
              borderRadius: BorderRadius.circular(12),
            ),
            child: HighlightView(
              sampleCode,
              language: 'java',
              theme: atomOneDarkTheme,
              padding: EdgeInsets.zero,
              textStyle: GoogleFonts.firaCode(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Key Takeaways:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('• Inheritance allows Dog to reuse the sound() method from Animal.\n• It promotes code reusability.', style: TextStyle(color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildWhiteboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.brush, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Whiteboard feature coming soon!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
