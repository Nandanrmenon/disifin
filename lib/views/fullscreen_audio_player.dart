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
              Spacer(),
              if (AudioPlayerService.currentTrackImageUrl != null &&
                  AudioPlayerService.currentTrackImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    AudioPlayerService.currentTrackImageUrl!,
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
                    child:
                        Card(child: const Icon(Icons.music_note, size: 200))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AudioPlayerService.currentTrackName ?? 'Now Playing',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
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
                      if (duration.inMilliseconds > 0) {
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
                                Text(position.toString().split('.').first),
                                const Spacer(),
                                Text(duration.toString().split('.').first),
                                const SizedBox(width: 25),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
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
                    onPressed: () {},
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
                    onPressed: () {},
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
