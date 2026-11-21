import 'package:camera/camera.dart';
import '../services/voice_service.dart';
import '../services/jarvis_command_service.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final VoiceService _voiceService = VoiceService();
  final JarvisCommandService _commandService = JarvisCommandService();
  bool _isInitializing = true;
  String? _error;

  bool _commandHandled = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startVoiceCommand() async {
    try {
      await _voiceService.startListening(
        locale: "en-US",
        onResult: (words) async {
          if (_commandHandled || !mounted) return;

          final command = _commandService.parseCommand(words);

          if (command == "stop_hand_interaction") {
            _commandHandled = true;
            await _voiceService.stopListening();
            await _stopCamera();

            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        onListeningChanged: (listening) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Voice Error: $e";
        });
      }
    }
  }
  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      final frontCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      final selectedCamera =
          frontCamera.isNotEmpty ? frontCamera.first : cameras.first;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      _startVoiceCommand();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _stopCamera() async {
    await _voiceService.stopListening();
    await _controller?.dispose();

    if (!mounted) return;

    setState(() {
      _controller = null;
    });
  }

   @override
  void dispose() {
    _voiceService.stopListening();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.cyanAccent,
        title: const Text('JARVIS CAMERA'),
      ),
      body: Center(
        child: _isInitializing
            ? const CircularProgressIndicator(
                color: Colors.cyanAccent,
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Camera Error:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : controller == null
                    ? const Text(
                        'Camera Stopped',
                        style: TextStyle(color: Colors.white),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'CAMERA SYSTEM ACTIVE',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(controller),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: ElevatedButton.icon(
                              onPressed: _stopCamera,
                              icon: const Icon(Icons.stop),
                              label: const Text('STOP CAMERA'),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
