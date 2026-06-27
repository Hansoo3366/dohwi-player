import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Android 13 이상에서 백그라운드 재생(Foreground Service)을 위한 알림 권한 요청
  await Permission.notification.request();

  // 오디오 세션 초기화 (시스템에 정식 미디어 플레이어로 인식시키기 위함)
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final audioHandler = await AudioService.init(
    builder: AppAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.kids_music_player.audio',
      androidNotificationChannelName: '도휘 플레이어 재생',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );

  runApp(KidsMusicPlayerApp(audioHandler: audioHandler));
}
