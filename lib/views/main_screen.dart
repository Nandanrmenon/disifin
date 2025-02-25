import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/fullscreen_audio_player.dart';
import 'package:disifin/views/home_page.dart';
import 'package:disifin/views/media_list_screen.dart';
import 'package:disifin/views/search_page.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    SearchPage(),
    MediaListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<PlayerState>(
              stream: AudioPlayerService.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final playing = playerState?.playing ?? false;
                final processingState = playerState?.processingState;
                if (processingState == ProcessingState.idle)
                  return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FullscreenAudioPlayer(),
                      ),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      leading:
                          AudioPlayerService.currentTrackImageUrl != null &&
                                  AudioPlayerService
                                      .currentTrackImageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                      AudioPlayerService.currentTrackImageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover),
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  child: const Icon(Icons.music_note)),
                      title: Text(
                        AudioPlayerService.currentTrackName ?? 'Now Playing',
                        maxLines: 1,
                        style: TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () {},
                          ),
                          IconButton.outlined(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () {
                              if (playing) {
                                AudioPlayerService.pause();
                              } else {
                                AudioPlayerService.resume();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: 'Media',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
