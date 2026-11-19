/// VoiceService - PLACEHOLDER ONLY.
///
/// This file exists so the project structure is ready for Step 2
/// (real speech-to-text and text-to-speech for Marathi + English).
///
/// NOTHING in this file is implemented or functional yet.
/// Do not call these methods expecting real behavior - they are
/// stubs that make the intended future API shape explicit.
class VoiceService {
  /// Will eventually start listening to the microphone and return
  /// recognized text. Not implemented yet.
  Future<String?> startListening({String locale = 'en-US'}) async {
    throw UnimplementedError(
      'Voice recognition is not implemented yet. Planned for Step 2.',
    );
  }

  /// Will eventually speak the given text out loud using TTS.
  /// Not implemented yet.
  Future<void> speak(String text, {String locale = 'en-US'}) async {
    throw UnimplementedError(
      'Text-to-speech is not implemented yet. Planned for Step 2.',
    );
  }
}
