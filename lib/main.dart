import 'package:disifin/theme.dart';
import 'package:disifin/views/album_list_screen.dart';
import 'package:disifin/views/artist_list_screen.dart';
import 'package:disifin/views/login_screen.dart';
import 'package:disifin/views/main_screen.dart'; // Add this import
import 'package:disifin/views/media_list_screen.dart';
import 'package:disifin/views/music_player.dart';
import 'package:disifin/views/search_page.dart'; // Add this import
import 'package:disifin/views/track_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getString('accessToken') != null;

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
      },
    );
  }
}
