import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:convert';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/interactive_quiz_widget.dart';

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
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage('Hello! I am Vastavik Bot. How can I assist you today?', false),
  ];
  bool _isLoading = false;
  ChatSession? _chatSession;
  bool _showScrollToBottom = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _chatScrollController.addListener(() {
      if (_chatScrollController.hasClients) {
        final maxScroll = _chatScrollController.position.maxScrollExtent;
        final currentScroll = _chatScrollController.offset;
        final shouldShow = maxScroll - currentScroll > 200;
        if (_showScrollToBottom != shouldShow) {
          setState(() {
            _showScrollToBottom = shouldShow;
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

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
      if (_chatSession == null) {
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
          systemInstruction: Content.system('You are Vastavik Bot, an AI coding assistant powered by the Kimi K3, designed for kids in ICSE schools. Keep your explanations simple, educational, and age-appropriate. If asked what model or version you are running, you must strictly state that you are Kimi K3.\n\nCRITICAL INSTRUCTION: If the user asks for a quiz, you MUST output the quiz ONLY as a JSON block wrapped in ```json ... ``` with the following structure: {"type": "quiz", "title": "Quiz Title", "questions": [{"question": "...", "options": ["A", "B", "C", "D"], "answerIndex": 0}]}. Do not add any text before or after the JSON block.'),
        );
        _chatSession = model.startChat();
      }
      
      final content = Content.text(text);
      final response = await _chatSession!.sendMessage(content);
      
      setState(() {
        _messages.add(ChatMessage(response.text ?? 'No response', false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Gemini AI Error: Make sure your API key is correct and valid.\n\nDetails: $e', false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
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
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('Vastavik Bot', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: const Text('Kimi K3', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _chatScrollController,
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
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _scrollToBottom,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      elevation: 4,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: _buildBotMessage(context, '*Developing...*'),
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
            child: MarkdownBody(
              data: text,
              builders: {
                'code': CodeElementBuilder(context),
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
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

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeText = element.textContent;
    final isBlock = codeText.contains('\n');

    if (isBlock) {
      try {
        final decoded = jsonDecode(codeText);
        if (decoded is Map<String, dynamic> && decoded['type'] == 'quiz') {
          return InteractiveQuizWidget(quizData: decoded);
        }
      } catch (e) {
        // Not a JSON quiz, just render as normal code block
      }
    }

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(codeText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: SelectableText(
              codeText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black87),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: codeText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.copy, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Copy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
