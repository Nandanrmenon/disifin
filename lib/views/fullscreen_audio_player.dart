import 'dart:ui' as ui;

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullscreenAudioPlayer extends StatefulWidget {
  const FullscreenAudioPlayer({super.key});

  @override
  State<FullscreenAudioPlayer> createState() => _FullscreenAudioPlayerState();
}

class _FullscreenAudioPlayerState extends State<FullscreenAudioPlayer> {
  double _sliderValue = 0.0;
  int _sliderStyle = 1;

  @override
  void initState() {
    super.initState();
    _loadSliderStyle();
  }

  Future<void> _loadSliderStyle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sliderStyle = prefs.getInt('sliderStyle') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<TrackInfo?>(
          stream: AudioPlayerService.currentTrackStream,
          builder: (context, snapshot) {
            final trackInfo = snapshot.data;
            final trackImageUrl = trackInfo?.imageUrl;
            return trackImageUrl != null && trackImageUrl.isNotEmpty
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: 20,
                      sigmaY: 20,
                    ),
                    child: Image.network(
                      trackImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container();
          },
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black54,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Symbols.keyboard_arrow_down),
                        ),
                        const Spacer(),
                        Text(
                          'Now Playing',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Symbols.more_vert),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<TrackInfo?>(
                    stream: AudioPlayerService.currentTrackStream,
                    builder: (context, snapshot) {
                      final trackInfo = snapshot.data;
                      final trackName = trackInfo?.name ?? 'Now Playing';
                      final trackArtist = trackInfo?.artist ?? 'Unknown Artist';
                      final trackImageUrl = trackInfo?.imageUrl;
                      return Column(
                        children: [
                          if (trackImageUrl != null && trackImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                trackImageUrl,
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.width * 0.9,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.width * 0.9,
                              color: Theme.of(context).canvasColor,
                              child: const Card(
                                child: Icon(Symbols.music_note, size: 200),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  trackName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trackArtist,
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Duration?>(
                    stream: AudioPlayerService.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      if (duration == Duration.zero) {
                        return const Text('Loading...');
                      }
                      return StreamBuilder<Duration>(
                        stream: AudioPlayerService.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          _sliderValue = position.inMilliseconds.toDouble();
                          return Column(
                            children: [
                              if (_sliderStyle == 1)
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 20,
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                        elevation: 2,
                                        pressedElevation: 0),
                                    overlappingShapeStrokeColor: Colors.black,
                                    activeTrackColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    thumbColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Slider(
                                    value: _sliderValue.clamp(0.0,
                                        duration.inMilliseconds.toDouble()),
                                    min: 0.0,
                                    max: duration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      setState(() {
                                        _sliderValue = value;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      AudioPlayerService.seek(Duration(
                                          milliseconds: value.toInt()));
                                    },
                                  ),
                                )
                              else
                                Slider(
                                  year2023: false,
                                  value: _sliderValue.clamp(
                                      0.0, duration.inMilliseconds.toDouble()),
                                  min: 0.0,
                                  max: duration.inMilliseconds.toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      _sliderValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    AudioPlayerService.seek(
                                        Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              Row(
                                children: [
                                  const SizedBox(width: 25),
                                  Text(_formatDuration(position)),
                                  const Spacer(),
                                  Text(_formatDuration(duration)),
                                  const SizedBox(width: 25),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.repeat),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Symbols.skip_previous),
                        onPressed: AudioPlayerService.skipToPrevious,
                      ),
                      SizedBox(width: 20),
                      StreamBuilder<PlayerState>(
                        stream: AudioPlayerService.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;
                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) {
                            return const CircularProgressIndicator(
                              year2023: false,
                            );
                          } else if (playing != true) {
                            return IconButton.filled(
                              icon: Icon(
                                Symbols.play_arrow,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fill: 1,
                              ),
                              iconSize: 48.0,
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                              ),
                              onPressed: AudioPlayerService.resume,
                            );
                          } else if (processingState !=
                              ProcessingState.completed) {
                            return IconButton.filled(
                              icon: Icon(
                                Symbols.pause,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fill: 1,
                              ),
                              iconSize: 48.0,
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                              ),
                              onPressed: AudioPlayerService.pause,
                            );
                          } else {
                            return IconButton.filled(
                              icon: const Icon(Symbols.replay),
                              iconSize: 48.0,
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              onPressed: AudioPlayerService.resume,
                            );
                          }
                        },
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Symbols.skip_next),
                        onPressed: AudioPlayerService.skipToNext,
                      ),
                      IconButton(
                        icon: const Icon(Symbols.shuffle),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 100),
            child: Row(
              children: [
                IconButton(onPressed: () {}, icon: Icon(Symbols.lyrics)),
                Spacer(),
                IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        CupertinoSheetRoute(
                            builder: (context) => const QueueView())),
                    icon: const Icon(Symbols.queue_music))
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueutViewState();
}

class _QueutViewState extends State<QueueView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Symbols.keyboard_arrow_down),
              ),
              const Spacer(),
              Text('Next Up'),
              const Spacer(),
              SizedBox(width: 48),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: AudioPlayerService.currentQueue.length,
              itemBuilder: (context, index) {
                final trackName = AudioPlayerService.currentQueue[index];
                return ListTile(
                  title: Text(trackName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
