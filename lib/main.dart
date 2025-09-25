import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:disifin/globals.dart' as globals;
import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/services/database_service.dart';
import 'package:disifin/theme.dart';
import 'package:disifin/views/album_list_screen.dart';
import 'package:disifin/views/artist_list_screen.dart';
import 'package:disifin/views/fullscreen_audio_player.dart';
import 'package:disifin/views/login_screen.dart';
import 'package:disifin/views/main_screen.dart';
import 'package:disifin/views/media_list_screen.dart';
import 'package:disifin/views/music_player.dart';
import 'package:disifin/views/search_page.dart';
import 'package:disifin/views/track_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

late AudioHandler _audioHandler;
late AudioPlayerService _audioPlayerService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerService(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.nahnah.disifin.channel.audio',
      androidNotificationChannelName: 'Music playback',
    ),
  );

  _audioPlayerService = AudioPlayerService.initialize(_audioHandler);

  await DatabaseService.initDatabase();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getString('accessToken') != null;
  globals.baseUrl = prefs.getString('serverName') ?? '';

  final themeNotifier = ThemeNotifier(await getAppTheme());
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(1000, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: MyApp(
          isLoggedIn: isLoggedIn, audioPlayerService: _audioPlayerService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final AudioPlayerService audioPlayerService;

  const MyApp(
      {super.key, required this.isLoggedIn, required this.audioPlayerService});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Disifin',
          theme: themeNotifier.themeData,
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
          initialRoute: isLoggedIn ? '/main' : '/login',
          routes: {
            '/': (context) =>
                MainScreen(audioPlayerService: audioPlayerService),
            '/music': (context) => const MusicPlayer(),
            '/login': (context) => const LoginScreen(),
            '/tracks': (context) =>
                TrackListScreen(audioPlayerService: audioPlayerService),
            '/albums': (context) => const AlbumListScreen(),
            '/artists': (context) => const ArtistListScreen(),
            '/media': (context) =>
                MediaListScreen(audioPlayerService: audioPlayerService),
            '/search': (context) => const SearchPage(),
            '/main': (context) =>
                MainScreen(audioPlayerService: audioPlayerService),
            '/fullscreen_audio_player': (context) =>
                const FullscreenAudioPlayer(),
          },
        );
      },
    );
  }
}
