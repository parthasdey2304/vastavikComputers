import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/theme/app_theme.dart';

class VideoLessonScreen extends StatefulWidget {
  const VideoLessonScreen({super.key});

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'KzZJ0g7QZyk', // Dummy unlisted video ID for Java OOP
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Java Programming', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border, color: AppTheme.textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _controller,
              backgroundColor: Colors.black,
            ),
          ),
          
          // Details
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Object-Oriented Programming (OOP)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        SizedBox(height: 8),
                        Text('Learn the fundamentals of classes, objects, and inheritance in Java.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicatorColor: AppTheme.primary,
                    tabs: [
                      Tab(text: 'Code & Notes'),
                      Tab(text: 'Whiteboard'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCodeTab(),
                        _buildWhiteboardTab(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCodeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Implementation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.codeBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'class Animal {\n  void sound() {\n    System.out.println("Bark");\n  }\n}\n\nclass Dog extends Animal {}',
            style: TextStyle(fontFamily: 'monospace', color: AppTheme.codeText, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.draw, size: 64, color: AppTheme.textSecondary.withAlpha(50)),
          const SizedBox(height: 16),
          const Text('Whiteboard snapshot will appear here', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
