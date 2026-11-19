import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/jarvis_orb.dart';

/// Working chat screen.
///
/// What IS functional right now:
///  - Typing a message and sending it
///  - Messages appear instantly in the list (user + a canned JARVIS reply)
///  - The orb animates and visually reacts to "listening" state
///  - Language selector (English / Marathi) - stores the selection only
///
/// What is NOT functional yet (by design, for Step 1):
///  - The microphone button does not record or recognize speech yet.
///    Tapping it shows an honest message instead of pretending to work.
///  - Replies are a fixed placeholder, not real Claude AI responses.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "JARVIS core online. Voice recognition and Claude AI are not "
          "connected yet in this build - that's coming in the next steps. "
          "You can still type to me below.",
      isUser: false,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  String _language = 'English';

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messages.add(
        ChatMessage(
          text:
              "I received your message: \"$text\". Real AI responses "
              "will be connected in Step 3 (Claude API integration).",
          isUser: false,
        ),
      );
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMicPressed() {
    setState(() => _isListening = !_isListening);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.panelColor,
        content: Text(
          _isListening
              ? 'Microphone UI activated (visual only). Real $_language '
                  'speech recognition is not implemented yet - planned for Step 2.'
              : 'Microphone deactivated.',
          style: const TextStyle(color: AppTheme.primaryBlue),
        ),
      ),
    );

    if (_isListening) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isListening = false);
      });
    }
  }

  void _toggleLanguage() {
    setState(() {
      _language = _language == 'English' ? 'Marathi' : 'English';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('JARVIS CHAT', style: TextStyle(letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              _language == 'English' ? 'EN' : 'मर',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: JarvisOrb(size: 90, isListening: _isListening),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.panelColor,
        border: Border(top: BorderSide(color: AppTheme.deepBlue, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _MicButton(isListening: _isListening, onPressed: _onMicPressed),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: _language == 'English'
                      ? 'Type a message...'
                      : 'संदेश टाइप करा...',
                  hintStyle: const TextStyle(color: AppTheme.mutedTextColor),
                  filled: true,
                  fillColor: AppTheme.deepBlue.withOpacity(0.3),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _MicButton({required this.isListening, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppTheme.primaryBlue.withOpacity(0.25)
              : AppTheme.deepBlue.withOpacity(0.4),
          border: Border.all(
            color: isListening ? AppTheme.primaryBlue : AppTheme.secondaryBlue,
            width: 1.5,
          ),
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          color: isListening ? AppTheme.primaryBlue : AppTheme.secondaryBlue,
        ),
      ),
    );
  }
}
