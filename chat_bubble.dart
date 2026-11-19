import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// Renders one chat message as a holographic-style bubble.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? AppTheme.userBubbleColor : AppTheme.aiBubbleColor;
    final borderColor = isUser
        ? AppTheme.primaryBlue.withOpacity(0.4)
        : AppTheme.secondaryBlue.withOpacity(0.5);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isUser ? 'YOU' : 'JARVIS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: isUser
                    ? AppTheme.primaryBlue
                    : AppTheme.secondaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: const TextStyle(color: AppTheme.textColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
