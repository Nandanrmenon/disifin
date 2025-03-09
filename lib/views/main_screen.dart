import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/fullscreen_audio_player.dart';
import 'package:disifin/views/home_page.dart';
import 'package:disifin/views/media_list_screen.dart';
import 'package:disifin/views/search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double _sliderValue = 0.0;

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

  Future<void> _checkToken() async {
    final token = await AudioPlayerService.getAccessToken();
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showFullscreenPlayer(BuildContext context) {
    Navigator.of(context).push(
      CupertinoSheetRoute(
        settings: RouteSettings(
          name: '/fullscreen_audio_player',
        ),
        builder: (context) => const FullscreenAudioPlayer(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkToken();
    _loadPlayerState();
  }

  Future<void> _loadPlayerState() async {
    await AudioPlayerService.loadPlayerState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 56,
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
                    _showFullscreenPlayer(context);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              StreamBuilder<TrackInfo?>(
                                stream: AudioPlayerService.currentTrackStream,
                                builder: (context, snapshot) {
                                  final trackInfo = snapshot.data;
                                  final trackName =
                                      trackInfo?.name ?? 'Now Playing';
                                  final trackImageUrl = trackInfo?.imageUrl;
                                  return Expanded(
                                    child: Row(
                                      children: [
                                        if (trackImageUrl != null &&
                                            trackImageUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              trackImageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 25,
                                            child:
                                                const Icon(Symbols.music_note),
                                          ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            trackName,
                                            maxLines: 1,
                                            style: TextStyle(
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Symbols.favorite),
                                onPressed: () {},
                              ),
                              IconButton.filledTonal(
                                icon: Icon(
                                  playing ? Symbols.pause : Symbols.play_arrow,
                                ),
                                onPressed: () {
                                  if (playing) {
                                    AudioPlayerService.pause();
                                  } else {
                                    AudioPlayerService.resume();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<Duration?>(
                            stream: AudioPlayerService.durationStream,
                            builder: (context, snapshot) {
                              final duration = snapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration>(
                                stream: AudioPlayerService.positionStream,
                                builder: (context, snapshot) {
                                  final position =
                                      snapshot.data ?? Duration.zero;
                                  _sliderValue =
                                      position.inMilliseconds.toDouble();
                                  return LinearProgressIndicator(
                                    year2023: false,
                                    value: duration.inMilliseconds > 0
                                        ? _sliderValue /
                                            duration.inMilliseconds.toDouble()
                                        : 0.0,
                                  );
                                },
                              );
                            },
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(0, 0, 0, 0),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Symbols.home_rounded),
              activeIcon: Icon(
                Symbols.home_rounded,
                fill: 1,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Symbols.search_rounded),
              activeIcon: Icon(
                Symbols.search_rounded,
                fill: 1,
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Symbols.art_track_rounded),
              activeIcon: Icon(
                Symbols.art_track_rounded,
                fill: 1,
              ),
              label: 'Library',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
      extendBody: true,
    );
  }
}
