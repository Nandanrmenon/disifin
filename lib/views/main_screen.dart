import 'dart:io';

import 'package:animations/animations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/fullscreen_audio_player.dart';
import 'package:disifin/views/home_page.dart';
import 'package:disifin/views/media_list_screen.dart';
import 'package:disifin/views/search_page.dart';
import 'package:disifin/widgets/applogo.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

late AudioHandler _audioHandler;

class MainScreen extends StatefulWidget {
  final AudioPlayerService audioPlayerService;

  const MainScreen({super.key, required this.audioPlayerService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double _sliderValue = 0.0;
  final PageController _pageController = PageController();
  bool railState = false;
  bool _amoledBackground = false;

  List<Widget> get _pages => <Widget>[
        const HomePage(),
        const SearchPage(),
        MediaListScreen(audioPlayerService: widget.audioPlayerService),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkToken() async {
    final token = await AudioPlayerService.getAccessToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showFullscreenPlayer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Navigator.of(context).push(
      MaterialPageRoute(
        // isScrollControlled: true,
        // useSafeArea: true,
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
    _loadAmoledBackground();
  }

  Future<void> _loadPlayerState() async {
    await widget.audioPlayerService
        .loadPlayerState(context as AudioPlayerService);
    setState(() {});
  }

  Future<void> _loadAmoledBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _amoledBackground = prefs.getBool('amoledBackground') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      // Use a different view for larger screens
      return Scaffold(
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 24, 24, 24),
                  border: Border(
                      right: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.outline))),
              child: SafeArea(
                bottom: false,
                top: Platform.isAndroid || Platform.isIOS ? true : false,
                child: Column(
                  crossAxisAlignment: railState
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (Platform.isMacOS)
                      SizedBox(
                        height: 30,
                      ),
                    if (!railState)
                      IconButton(
                          tooltip: 'Open',
                          onPressed: () {
                            setState(() {
                              railState = !railState;
                            });
                            print(railState);
                          },
                          icon: Icon(Symbols.menu)),
                    if (railState)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                          IconButton(
                              tooltip: 'Close',
                              onPressed: () {
                                setState(() {
                                  railState = !railState;
                                });
                                print(railState);
                              },
                              icon: Icon(Symbols.arrow_back)),
                          SizedBox(
                            width: 18,
                          ),
                          AppLogo(),
                          SizedBox(
                            width: 4,
                          ),
                          Text(
                            'Disifin',
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        ],
                      ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _onItemTapped,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Symbols.home_rounded),
                              selectedIcon: Icon(
                                Symbols.home_rounded,
                                fill: 1,
                              ),
                              label: Text('Home'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Symbols.search_rounded),
                              selectedIcon: Icon(
                                Symbols.search_rounded,
                                fill: 1,
                              ),
                              label: Text('Search'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Symbols.art_track_rounded),
                              selectedIcon: Icon(
                                Symbols.art_track_rounded,
                                fill: 1,
                              ),
                              label: Text('Library'),
                            ),
                          ],
                          extended: railState,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (
                  Widget child,
                  Animation<double> primaryAnimation,
                  Animation<double> secondaryAnimation,
                ) {
                  return FadeTransition(
                    opacity: primaryAnimation,
                    child: ScaleTransition(
                      filterQuality: FilterQuality.high,
                      scale: Tween<double>(
                        begin: 0.99,
                        end: 1.0,
                      ).animate(primaryAnimation),
                      child: child,
                    ),
                  );
                },
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomPlayer(context),
        extendBody: true,
      );
    }

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeTransition(
            opacity: primaryAnimation,
            child: ScaleTransition(
              filterQuality: FilterQuality.high,
              scale: Tween<double>(
                begin: 0.99,
                end: 1.0,
              ).animate(primaryAnimation),
              child: child,
            ),
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomPlayer(context),
      extendBody: true,
    );
  }

  Widget _buildBottomPlayer(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragEnd: (details) => _showFullscreenPlayer(context),
          child: StreamBuilder<PlayerState>(
            stream: AudioPlayerService.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final playing = playerState?.playing ?? false;
              final processingState = playerState?.processingState;
              if (processingState == ProcessingState.idle) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () {
                  _showFullscreenPlayer(context);
                },
                child: Card(
                  // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  margin: EdgeInsets.zero,
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
                                          trackImageUrl.isNotEmpty &&
                                          Uri.tryParse(trackImageUrl)
                                                  ?.hasAbsolutePath ==
                                              true)
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
                                          child: const Icon(Symbols.music_note),
                                        ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          trackName,
                                          maxLines: 1,
                                          style: TextStyle(
                                              overflow: TextOverflow.ellipsis),
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
                                  AudioPlayerService.pausePlayback();
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
                                final position = snapshot.data ?? Duration.zero;
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
        if (screenWidth > 600)
          SizedBox(
            height: 20,
          ),
        if (screenWidth <= 600)
          BottomNavigationBar(
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
      ],
    );
  }
}
