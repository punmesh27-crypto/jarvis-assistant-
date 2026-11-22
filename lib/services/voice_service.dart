import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<bool> initialize({
    Function(bool)? onListeningChanged,
  }) async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onStatus: (status) {
        final listening = status == 'listening';
        onListeningChanged?.call(listening);
      },
      onError: (error) {
        _initialized = false;
      },
    );

    return _initialized;
  }

  Future<void> startListening({
    String locale = 'en-US',
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
    Function(String)? onFinalResult,
  }) async {
    if (_speech.isListening) return;

    final available = await initialize(
      onListeningChanged: onListeningChanged,
    );

    if (!available) {
      throw Exception('Speech recognition is not available.');
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onFinalResult?.call(result.recognizedWords);
        }
      },
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> speak(
    String text, {
    String locale = 'en-US',
  }) async {
    if (text.trim().isEmpty) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  bool get isListening => _speech.isListening;
}
