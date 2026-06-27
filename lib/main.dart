import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final audioHandler = await AudioService.init(
    builder: AppAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.kids_music_player.audio',
      androidNotificationChannelName: '도휘 플레이어 재생',
      androidNotificationOngoing: true,
    ),
  );

  runApp(KidsMusicPlayerApp(audioHandler: audioHandler));
}
