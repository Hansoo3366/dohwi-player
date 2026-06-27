import 'package:flutter/material.dart';

import 'controllers/player_controller.dart';
import 'repositories/song_repository.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_audio_handler.dart';
import 'theme/app_theme.dart';

class KidsMusicPlayerApp extends StatefulWidget {
  const KidsMusicPlayerApp({required this.audioHandler, super.key});

  final AppAudioHandler audioHandler;

  @override
  State<KidsMusicPlayerApp> createState() => _KidsMusicPlayerAppState();
}

class _KidsMusicPlayerAppState extends State<KidsMusicPlayerApp> {
  late final PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController(widget.audioHandler);
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '도휘 플레이어',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: _SplashGate(
        child: HomeScreen(
          songRepository: SongRepository(),
          playerController: _playerController,
        ),
      ),
    );
  }
}

/// 앱 진입 시 잠깐 전체화면 스플래시를 보여준 뒤 [child]로 전환한다.
class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.child});

  final Widget child;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  static const _splashDuration = Duration(milliseconds: 1600);
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashDuration, () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showSplash ? const SplashScreen() : widget.child,
    );
  }
}
