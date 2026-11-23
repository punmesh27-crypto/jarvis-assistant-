import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Jarvis3DHologram extends StatelessWidget {
  const Jarvis3DHologram({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF020B18)),
        ModelViewer(
          src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          alt: 'JARVIS 3D Hologram',
          ar: false,
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
          backgroundColor: const Color(0xFF020B18),
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
