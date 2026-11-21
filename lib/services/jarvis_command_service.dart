import 'package:flutter/foundation.dart';

class JarvisCommandService {
  String? parseCommand(String input) {
    final text = input.toLowerCase().trim();

    if (text.contains('start hand interaction')) {
      return 'start_hand_interaction';
    }

    if (text.contains('stop hand interaction')) {
      return 'stop_hand_interaction';
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
    if (kDebugMode) {
      debugPrint('JARVIS Command: $command');
    }
  }
}
