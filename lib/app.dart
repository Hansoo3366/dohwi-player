import 'package:flutter/material.dart';

import 'controllers/player_controller.dart';
import 'repositories/song_repository.dart';
import 'screens/home_screen.dart';
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
      home: HomeScreen(
        songRepository: SongRepository(),
        playerController: _playerController,
      ),
    );
  }
}
