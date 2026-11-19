import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/jarvis_orb.dart';
import '../widgets/hologram_interface.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  const Center(
                    child: JarvisOrb(size: 180),
                  ),
                ],
              ),
            ),
            const Spacer(),
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
                        builder: (_) => const ChatScreen(),
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
