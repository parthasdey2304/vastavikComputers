import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/theme/app_theme.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lessonData;
  const LessonDetailScreen({super.key, required this.lessonData});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  YoutubePlayerController? _ytController;
  bool _videoError = false;

  String get _title => widget.lessonData['title']?.toString() ?? 'Lesson';
  String get _description => widget.lessonData['description']?.toString() ?? '';
  String get _youtubeUrl => widget.lessonData['youtubeUrl']?.toString() ?? '';
  String get _duration => widget.lessonData['duration']?.toString() ?? '';
  int get _positionSec =>
      (widget.lessonData['youtubePositionSec'] is num)
          ? (widget.lessonData['youtubePositionSec'] as num).toInt()
          : 0;
  String get _whiteboardUrl =>
      widget.lessonData['whiteboardImageUrl']?.toString() ?? '';
  String get _codeSample => widget.lessonData['codeSample']?.toString() ?? '';
  String get _notes => widget.lessonData['notes']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initVideo();
  }

  void _initVideo() {
    if (_youtubeUrl.isEmpty) return;
    final videoId = YoutubePlayerController.convertUrlToId(_youtubeUrl);
    if (videoId == null) {
      setState(() => _videoError = true);
      return;
    }
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      startSeconds: _positionSec.toDouble(),
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
      ),
    );
    _ytController!.stream.listen((value) {
      if (!mounted) return;
      final isEnded = value.playerState == PlayerState.ended;
      if ((isEnded || value.hasError) && !_videoError) {
        setState(() => _videoError = true);
      }
    });
  }

  @override
  void dispose() {
    _ytController?.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_duration.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _duration,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _ytController != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      YoutubePlayer(
                        controller: _ytController!,
                        aspectRatio: 16 / 9,
                      ),
                      if (_videoError)
                        Container(
                          color: Colors.black,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline,
                                  color: Colors.white38, size: 48),
                              SizedBox(height: 12),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'This video could not be played. Make sure the video is set to "Unlisted" (not Private) on YouTube.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill,
                              color: Colors.white30, size: 64),
                          SizedBox(height: 8),
                          Text('No video attached for this lesson yet.',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
          ),

          // Header info
          Container(
            width: double.infinity,
            color: context.appSurface,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                if (_description.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    _description,
                    style:
                        TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          Container(
            color: context.appSurface,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
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
              color: const Color(0xFFF8FAFC),
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
    final hasCode = _codeSample.trim().isNotEmpty;
    final hasNotes = _notes.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCode) ...[
            Text(
              'Implementation:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HighlightView(
                _codeSample,
                language: 'java',
                theme: atomOneDarkTheme,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.firaCode(fontSize: 14, height: 1.5),
              ),
            ),
            SizedBox(height: 24),
          ],
          if (hasNotes) ...[
            Text(
              'Key Takeaways:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(_notes,
                style:
                    TextStyle(color: Colors.black87, height: 1.5)),
          ],
          if (!hasCode && !hasNotes)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No code or notes added for this lesson yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardTab() {
    final url = _whiteboardUrl;
    if (url.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.brush, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No whiteboard image for this lesson yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: Center(
              child: Text(
                'Could not load whiteboard image.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
