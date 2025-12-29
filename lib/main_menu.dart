import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pages/tasklist.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> _playClick() async {
      final p = AudioPlayer();
      try {
        await p.play(AssetSource('click.mp3'));
        // keep alive briefly so playback isn't cut
        Future.delayed(const Duration(milliseconds: 800), () async {
          try {
            await p.dispose();
          } catch (_) {}
        });
      } catch (_) {
        try {
          await p.dispose();
        } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Pet')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _playClick();
                Navigator.pushNamed(context, '/timer');
              },
              child: const Text('Ir al Pomodoro'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskPage()),
                );
              },
              child: const Text('Ir a TaskList'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _playClick();
              },
              child: const Text('Pestaña 3 (sin acción)'),
            ),
          ],
        ),
      ),
    );
  }
}
