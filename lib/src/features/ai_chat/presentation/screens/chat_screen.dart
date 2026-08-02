import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage('Hello Parth! I am your AI assistant. How can I help you with your coding today?', false),
  ];
  bool _isLoading = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _previousText = '';

  void _toggleListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {});
    } else {
      if (!_speechEnabled) {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) => setState(() {}),
          onError: (errorNotification) => setState(() {}),
        );
        if (!_speechEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available.')));
          }
          return;
        }
      }
      
      _previousText = _controller.text;
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {});
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      final newText = _previousText.isEmpty ? result.recognizedWords : '$_previousText ${result.recognizedWords}';
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textScrollController.hasClients) {
        _textScrollController.animateTo(
          _textScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text, true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final apiKey = AppConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        setState(() {
          _messages.add(ChatMessage('API Key not found. Please provide GEMINI_API_KEY as a build argument.', false));
        });
        return;
      }
      
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
      );
      
      final content = [Content.text(text)];
      final response = await model.generateContent(content);
      
      setState(() {
        _messages.add(ChatMessage(response.text ?? 'No response', false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Gemini AI Error: Make sure your API key is correct and valid.\n\nDetails: $e', false));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Vastavik Bot', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
              child: const Text('Gemini 3.6 Flash', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: msg.isUser ? _buildUserMessage(context, msg.text) : _buildBotMessage(context, msg.text),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildQuickActions(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBotMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(text, style: const TextStyle(color: AppTheme.textPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.surface,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildChip('Explain Code', () => _sendMessage('Can you explain this code snippet?')),
          const SizedBox(width: 8),
          _buildChip('Generate Quiz', () => _sendMessage('Generate 3 MCQs about Java OOP concepts with 4 options each.')),
          const SizedBox(width: 8),
          _buildChip('Find Bug', () => _sendMessage('Help me find a bug in my Flutter code.')),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: AppTheme.primary.withAlpha(20),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
                child: Scrollbar(
                  controller: _textScrollController,
                  child: TextField(
                    controller: _controller,
                    scrollController: _textScrollController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: _speechToText.isListening ? Colors.red.withAlpha(50) : AppTheme.primary.withAlpha(20),
              child: IconButton(
                icon: Icon(
                  _speechToText.isListening ? Icons.mic_off : Icons.mic,
                  color: _speechToText.isListening ? Colors.red : AppTheme.primary,
                ),
                onPressed: _toggleListening,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
