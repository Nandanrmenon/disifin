import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FullscreenAudioPlayer extends StatefulWidget {
  const FullscreenAudioPlayer({super.key});

  @override
  _FullscreenAudioPlayerState createState() => _FullscreenAudioPlayerState();
}

class _FullscreenAudioPlayerState extends State<FullscreenAudioPlayer> {
  double _sliderValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Now Playing',
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Spacer(),
              StreamBuilder<TrackInfo?>(
                stream: AudioPlayerService.currentTrackStream,
                builder: (context, snapshot) {
                  final trackInfo = snapshot.data;
                  final trackName = trackInfo?.name ?? 'Now Playing';
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
                            child: Icon(Icons.music_note, size: 200),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          trackName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<Duration?>(
                stream: AudioPlayerService.durationStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: AudioPlayerService.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      _sliderValue = position.inMilliseconds.toDouble();
                      return Column(
                        children: [
                          Slider(
                            value: _sliderValue,
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: AudioPlayerService.skipToPrevious,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: AudioPlayerService.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;
                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) {
                        return const CircularProgressIndicator();
                      } else if (playing != true) {
                        return IconButton.filled(
                          icon: const Icon(Icons.play_arrow),
                          iconSize: 48.0,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                          onPressed: AudioPlayerService.resume,
                        );
                      } else if (processingState != ProcessingState.completed) {
                        return IconButton.filled(
                          icon: const Icon(Icons.pause),
                          iconSize: 48.0,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                          onPressed: AudioPlayerService.pause,
                        );
                      } else {
                        return IconButton.filled(
                          icon: const Icon(Icons.replay),
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
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: AudioPlayerService.skipToNext,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const QueueView())),
                      icon: const Icon(Icons.queue_outlined))
                ],
              ),
            ],
          ),
        ),
      ),
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Next Up',
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: ListView.builder(
        itemCount: AudioPlayerService.currentQueue.length,
        itemBuilder: (context, index) {
          final trackName = AudioPlayerService.currentQueue[index];
          return ListTile(
            title: Text(trackName),
          );
        },
      ),
    );
  }
}
