import 'package:flutter/foundation.dart';

class JarvisCommandService {
  bool isWakeWord(String input) {
    final text = input.toLowerCase().trim();
    return RegExp(r"\bhey\s+jarvis\b").hasMatch(text);
  }

  String? parseCommand(String input) {
    final text = input.toLowerCase().trim();

    debugPrint('JARVIS Heard: $text');

    if (text.contains('stop hand interaction') ||
        text.contains('stop interaction') ||
        text.contains('stop camera')) {
      return 'stop_hand_interaction';
    }

    if (text.contains('start hand interaction') ||
        text.contains('start interaction')) {
      return 'start_hand_interaction';
    }

    if (text.contains('go to chat')) {
      return 'go_to_chat';
    }

    if (text.contains('sleep mode')) {
      return 'sleep_mode';
    }

    return null;
  }

  void debugCommand(String? command) {
    debugPrint('JARVIS Command: $command');
  }
}
