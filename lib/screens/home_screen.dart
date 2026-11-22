import '../services/voice_service.dart';
import '../services/jarvis_command_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/jarvis_orb.dart';
import '../widgets/hologram_interface.dart';
import 'chat_screen.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAI = "Auto Mode";
  final VoiceService _voiceService = VoiceService();
  final JarvisCommandService _commandService = JarvisCommandService();
  bool _isListening = false;
  bool _commandHandled = false;


  Future<void> _startVoiceCommand({
    bool waitingForWakeWord = true,
  }) async {
    if (_isListening) return;

    _commandHandled = false;

    try {
      await _voiceService.startListening(
        locale: "en-US",
        onResult: (words) async {
          if (!mounted || _commandHandled) return;

          if (waitingForWakeWord) {
            if (!_commandService.isWakeWord(words)) return;

            _commandHandled = true;
            await _voiceService.stopListening();

            if (!mounted) return;
            setState(() => _isListening = false);

            await _voiceService.speak("Yes?", locale: "en-US");

            if (mounted) {
              await _startVoiceCommand(waitingForWakeWord: false);
            }
            return;
          }

          final command = _commandService.parseCommand(words);
          if (command == null) return;

          _commandHandled = true;
          await _voiceService.stopListening();

          if (!mounted) return;
          setState(() => _isListening = false);

          _commandService.debugCommand(command);

          if (command == "start_hand_interaction") {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CameraScreen(),
              ),
            );
          } else if (command == "go_to_chat") {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(selectedAI: selectedAI),
              ),
            );
          } else if (command == "sleep_mode") {
            await _voiceService.stopListening();
          }
        },
        onListeningChanged: (listening) {
          if (mounted) {
            setState(() => _isListening = listening);
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voice error: $error")),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'J A R V I S',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SYSTEM STANDING BY',
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const HologramInterface(),
                  Center(
                    child: GestureDetector(
                      onTap: _startVoiceCommand,
                      child: JarvisOrb(
                        size: 180,
                        isListening: _isListening,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: DropdownButtonFormField<String>(
                value: selectedAI,
                dropdownColor: AppTheme.panelColor,
                style: const TextStyle(color: AppTheme.primaryBlue),
                decoration: const InputDecoration(
                  labelText: "SELECT AI MODEL",
                  labelStyle: TextStyle(color: AppTheme.mutedTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
                items: ["Auto Mode", "ChatGPT", "Gemini", "Claude"]
                    .map((ai) => DropdownMenuItem(
                          value: ai,
                          child: Text(ai),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedAI = value);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("CAMERA INTERACTION"),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CameraScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.panelColor,
                    foregroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(selectedAI: selectedAI),
                      ),
                    );
                  },
                  child: const Text(
                    'ENTER CHAT INTERFACE',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
