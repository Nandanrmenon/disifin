import 'dart:io';

import 'package:disifin/globals.dart' as globals;
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
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

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
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

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
            '/': (context) => const MainScreen(),
            '/music': (context) => const MusicPlayer(),
            '/login': (context) => const LoginScreen(),
            '/tracks': (context) => const TrackListScreen(),
            '/albums': (context) => const AlbumListScreen(),
            '/artists': (context) => const ArtistListScreen(),
            '/media': (context) => const MediaListScreen(),
            '/search': (context) => const SearchPage(),
            '/main': (context) => const MainScreen(),
            '/fullscreen_audio_player': (context) =>
                const FullscreenAudioPlayer(),
          },
        );
      },
    );
  }
}
