import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/theme/app_theme.dart';

class VideoLessonScreen extends StatefulWidget {
  final Map<String, dynamic>? lessonData;
  const VideoLessonScreen({super.key, this.lessonData});

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  late YoutubePlayerController? _controller;
  bool _videoError = false;

  Map<String, dynamic> get _data => widget.lessonData ?? const {};
  String get _title => _data['title']?.toString() ?? 'Java Programming';
  String get _description =>
      _data['description']?.toString() ?? 'Learn the fundamentals of classes, objects, and inheritance in Java.';
  String get _youtubeUrl => _data['youtubeUrl']?.toString() ?? 'https://www.youtube.com/watch?v=KzZJ0g7QZyk';
  int get _positionSec =>
      (_data['youtubePositionSec'] is num)
          ? (_data['youtubePositionSec'] as num).toInt()
          : 0;
  String get _whiteboardUrl => _data['whiteboardImageUrl']?.toString() ?? '';
  String get _codeSample => _data['codeSample']?.toString() ?? '';
  String get _notes => _data['notes']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final videoId = YoutubePlayerController.convertUrlToId(_youtubeUrl);
    if (videoId == null) {
      setState(() => _videoError = true);
      _controller = null;
      return;
    }
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      startSeconds: _positionSec.toDouble(),
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    _controller!.stream.listen((value) {
      if (mounted && value.hasError && !_videoError) {
        setState(() => _videoError = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_title, style: TextStyle(color: context.appTextPrimary, fontSize: 16)),
        actions: [
          IconButton(icon: Icon(Icons.bookmark_border, color: context.appTextPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _controller != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      YoutubePlayer(
                        controller: _controller!,
                        backgroundColor: Colors.black,
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
                          Icon(Icons.lock_outline,
                              color: Colors.white38, size: 48),
                          SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No playable video attached to this lesson.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Details
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    color: context.appSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                        SizedBox(height: 8),
                        Text(_description, style: TextStyle(color: context.appTextSecondary)),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: context.appTextSecondary,
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
    final hasCode = _codeSample.trim().isNotEmpty;
    final hasNotes = _notes.trim().isNotEmpty;
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        if (hasCode) ...[
          Text('Implementation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              textStyle: GoogleFonts.firaCode(fontSize: 13, height: 1.5),
            ),
          ),
        ],
        if (hasNotes) ...[
          SizedBox(height: 24),
          Text('Key Takeaways:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text(_notes, style: TextStyle(height: 1.5)),
        ],
        if (!hasCode && !hasNotes)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No code or notes added for this lesson yet.',
                style: TextStyle(color: context.appTextSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWhiteboardTab() {
    final url = _whiteboardUrl;
    if (url.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.draw, size: 64, color: context.appTextSecondary.withAlpha(50)),
            SizedBox(height: 16),
            Text('No whiteboard snapshot for this lesson yet.', style: TextStyle(color: context.appTextSecondary)),
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
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            height: 300,
            color: context.appSurface,
            child: Center(
              child: Text(
                'Could not load whiteboard image.',
                style: TextStyle(color: context.appTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
