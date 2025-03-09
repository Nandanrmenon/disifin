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
import 'package:shared_preferences/shared_preferences.dart';

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

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disifin',
      theme: appTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn
          ? '/main'
          : '/login', // Set initial route based on login status
      routes: {
        '/': (context) => const MainScreen(), // Change this to MainScreen
        '/music': (context) => const MusicPlayer(),
        '/login': (context) => const LoginScreen(),
        '/tracks': (context) => const TrackListScreen(),
        '/albums': (context) => const AlbumListScreen(),
        '/artists': (context) => const ArtistListScreen(),
        '/media': (context) => const MediaListScreen(),
        '/search': (context) => const SearchPage(),
        '/main': (context) => const MainScreen(), // Add this route
        '/fullscreen_audio_player': (context) => const FullscreenAudioPlayer(),
      },
    );
  }
}
