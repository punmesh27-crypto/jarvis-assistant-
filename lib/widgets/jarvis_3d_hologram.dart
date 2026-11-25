import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Jarvis3DHologram extends StatefulWidget {
  final String modelUrl;

  const Jarvis3DHologram({
    super.key,
    this.modelUrl = 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
  });

  @override
  State<Jarvis3DHologram> createState() => _Jarvis3DHologramState();
}

class _Jarvis3DHologramState extends State<Jarvis3DHologram> {
  bool _isLoading = true;
  bool _hasError = false;

  static const String _modelEventsJs = '''
    const viewer = document.querySelector('model-viewer');
    if (viewer) {
      viewer.addEventListener('load', () => {
        JarvisModelChannel.postMessage('load');
      });
      viewer.addEventListener('error', () => {
        JarvisModelChannel.postMessage('error');
      });
    }
  ''';

  void _onModelMessage(JavaScriptMessage message) {
    if (!mounted) return;

    setState(() => {
      _isLoading = false;
      _hasError = message.message == 'error';
    });
  }

  @override
  void didUpdateWidget(covariant Jarvis3DHologram oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.modelUrl != widget.modelUrl) {
      _isLoading = true;
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF020B18)),
        ModelViewer(
          src: widget.modelUrl,
          alt: 'JARVIS 3D Hologram',
          loading: Loading.eager,
          ar: false,
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
          backgroundColor: const Color(0xFF020B18),
          relatedJs: _modelEventsJs,
          javascriptChannels: {
            JavascriptChannel(
              'JarvisModelChannel',
              onMessageReceived: _onModelMessage,
            ),
          },
        ),
        if (_isLoading)
          Container(
            color: const Color(0xAA020B18),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00D9FF),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'JARVIS 3D MODEL LOADING...',
                    style: TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_hasError)
          Container(
            color: const Color(0xEE020B18),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.orangeAccent,
                    size: 38,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3D MODEL COULD NOT LOAD',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check internet connection or model URL.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF00BFFF).withValues(alpha: 0.08),
                  const Color(0xFF020B18).withValues(alpha: 0.65),
                ],
                stops: const [0.45, 0.75, 1.0],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 12,
          left: 12,
          child: Text(
            'J.A.R.V.I.S  //  3D HOLOGRAM',
            style: TextStyle(
              color: Color(0xFF00D9FF),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Positioned(
          bottom: 12,
          right: 12,
          child: Text(
            'TOUCH TO ROTATE  •  PINCH TO ZOOM',
            style: TextStyle(
              color: Color(0xFF70CFFF),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
