import 'dart:async';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/voice_service.dart';
import '../services/jarvis_command_service.dart';

class CameraScreen extends StatefulWidget {
  final ValueChanged<String>? onSwipe;
  final ValueChanged<int>? onSelect;

  const CameraScreen({super.key, this.onSwipe, this.onSelect});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  HandLandmarkerPlugin? _handLandmarker;
  StreamSubscription<List<Hand>>? _handSubscription;
  bool _isProcessingFrame = false;
  DateTime _lastProcessedFrame = DateTime.fromMillisecondsSinceEpoch(0);
  String _gestureStatus = "Show your hand";
  double _cursorX = 0.5;
  double _cursorY = 0.5;
  bool _showCursor = false;
  bool _wasPinching = false;
  int _selectionCount = 0;
  double? _lastSwipeX;
  DateTime? _lastSwipeTime;
  String _swipeDirection = "";
  int _menuIndex = 0;
  final List<String> _menuOptions = ["AI MODEL", "CAMERA INTERACTION", "CHAT INTERFACE"];

  final VoiceService _voiceService = VoiceService();
  final JarvisCommandService _commandService =
      JarvisCommandService();

  bool _isInitializing = true;
  bool _commandHandled = false;

  String? _error;
  String _heardWords = 'Waiting for voice...';

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _initializeHandLandmarker() async {
    _handLandmarker = HandLandmarkerPlugin.create(
      numHands: 1,
      minHandDetectionConfidence: 0.7,
      delegate: HandLandmarkerDelegate.cpu,
    );

    _handSubscription = _handLandmarker!.landmarkStream.listen(
      _onHandLandmarks,
      onError: (error) {
        debugPrint("Hand tracking error: $error");
      },
    );
  }

  void _onHandLandmarks(List<Hand> hands) {
    if (!mounted) return;
    String status = "Show your hand";
    bool menuChanged = false;
    final wasPinching = _wasPinching;
    _wasPinching = false;
    _showCursor = false;
    if (hands.isEmpty || (hands.isNotEmpty && hands.first.landmarks.length >= 21 && !(hands.first.landmarks[8].y < hands.first.landmarks[6].y && hands.first.landmarks[12].y < hands.first.landmarks[10].y && hands.first.landmarks[16].y < hands.first.landmarks[14].y && hands.first.landmarks[20].y < hands.first.landmarks[18].y))) {
      _lastSwipeX = null;
      _lastSwipeTime = null;
    }
    if (hands.isNotEmpty && hands.first.landmarks.length >= 21) {
      final points = hands.first.landmarks;
      final palmX = points[9].x;
      final indexUp = points[8].y < points[6].y;
      final middleUp = points[12].y < points[10].y;
      final ringUp = points[16].y < points[14].y;
      final pinkyUp = points[20].y < points[18].y;
      final dx = points[4].x - points[8].x;
      final dy = points[4].y - points[8].y;
      final isPinching = dx * dx + dy * dy < 0.0036;
      if (isPinching) {
        status = "PINCH - Select";
        if (!wasPinching) { _selectionCount++; widget.onSelect?.call(_menuIndex); }
        _wasPinching = true;
      } else if (indexUp && !middleUp && !ringUp && !pinkyUp) {
        status = "POINT FINGER - Cursor";
        _cursorX = (1.0 - points[8].x).clamp(0.0, 1.0);
        _cursorY = points[8].y.clamp(0.0, 1.0);
        _showCursor = true;
      } else if (indexUp && middleUp && ringUp && pinkyUp) {
        final now = DateTime.now();
        if (_lastSwipeX == null || _lastSwipeTime == null) {
          _lastSwipeX = palmX;
          _lastSwipeTime = now;
        } else {
          final elapsed = now.difference(_lastSwipeTime!).inMilliseconds;
          final movement = palmX - _lastSwipeX!;
          if (elapsed > 700) {
            _lastSwipeX = palmX;
            _lastSwipeTime = now;
          } else if (elapsed >= 80 && movement.abs() >= 0.18) {
             _swipeDirection = movement < 0 ? "LEFT" : "RIGHT";
            _menuIndex = movement < 0
                ? (_menuIndex + 1) % _menuOptions.length
                : (_menuIndex - 1 + _menuOptions.length) % _menuOptions.length;
            menuChanged = true;
            widget.onSwipe?.call(_swipeDirection);
            status = "SWIPE $_swipeDirection";
            _lastSwipeX = null;
            _lastSwipeTime = null;
          } else {
            status = "OPEN PALM - Active";
          }
        }
      }
    }
    if (menuChanged || status != _gestureStatus || status == "POINT FINGER - Cursor" || status.startsWith("SWIPE ") || (status == "PINCH - Select" && !wasPinching)) {
      setState(() { _gestureStatus = status; });
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No camera found.");
      }

      final frontCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final selectedCamera = frontCamera.isNotEmpty
          ? frontCamera.first
          : cameras.first;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      _controller = controller;
      await controller.initialize();

      if (!mounted) {
        await _releaseCameraResources();
        return;
      }

      setState(() {
        _isInitializing = false;
      });

      await _initializeHandLandmarker();
      await controller.startImageStream(_processCameraImage);
      await _startVoiceCommand();
    } catch (e) {
      await _releaseCameraResources();
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  void _processCameraImage(CameraImage image) {
    final landmarker = _handLandmarker;
    final controller = _controller;
    if (landmarker == null || controller == null || _isProcessingFrame) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessedFrame).inMilliseconds < 150) return;
    _lastProcessedFrame = now;
    _isProcessingFrame = true;
    try {
      landmarker.processFrame(
        image,
        controller.description.sensorOrientation,
      );
    } catch (e) {
      debugPrint("Frame processing error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _startVoiceCommand() async {
    try {
      await _voiceService.startListening(
        locale: 'en-US',
        onResult: (words) async {
          if (!mounted) return;

          setState(() {
            _heardWords = words;
          });

          if (_commandHandled) return;

          final command =
              _commandService.parseCommand(words);

          if (command == 'stop_hand_interaction') {
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
      if (!mounted) return;

      setState(() {
        _error = 'Voice Error: $e';
      });
    }
  }

  Future<void> _releaseCameraResources() async {
    final controller = _controller;
    final subscription = _handSubscription;
    final landmarker = _handLandmarker;

    _controller = null;
    _handSubscription = null;
    _handLandmarker = null;

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (e) {
        debugPrint("Camera stream stop error: $e");
      }
    }

    await subscription?.cancel();
    landmarker?.dispose();

    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _stopCamera() async {
    await _voiceService.stopListening();
    await _releaseCameraResources();
    if (!mounted) return;
    setState(() {
      _controller = null;
      _gestureStatus = "Show your hand";
    });
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    unawaited(_releaseCameraResources());
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
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
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
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              "SELECTED MENU: ${_menuOptions[_menuIndex]}\nGesture: $_gestureStatus\nSelections: $_selectionCount\nHeard: $_heardWords",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio:
                                    controller.value.aspectRatio,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(controller),
                                    if (_showCursor)
                                      Align(
                                        alignment: Alignment(
                                          _cursorX * 2 - 1,
                                          _cursorY * 2 - 1,
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.cyanAccent,
                                          size: 30,
                                        ),
                                      ),
                                  ],
                                ),
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
