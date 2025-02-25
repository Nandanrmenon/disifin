import 'package:just_audio/just_audio.dart';

class TrackInfo {
  final String? name;
  final String? imageUrl;

  TrackInfo({this.name, this.imageUrl});
}

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentTrackName;
  static String? currentTrackImageUrl;

  static Future<void> play(
      String url, String trackName, String trackImageUrl) async {
    try {
      currentTrackName = trackName;
      currentTrackImageUrl = trackImageUrl;
      await _audioPlayer.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        tag: TrackInfo(name: trackName, imageUrl: trackImageUrl),
      ));
      _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  static Future<void> playQueue(List<String> urls, List<String> trackNames,
      List<String> trackImageUrls) async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: List.generate(urls.length, (index) {
          return AudioSource.uri(
            Uri.parse(urls[index]),
            tag: TrackInfo(
                name: trackNames[index], imageUrl: trackImageUrls[index]),
          );
        }),
      );
      await _audioPlayer.setAudioSource(playlist);
      currentTrackName = trackNames[0];
      currentTrackImageUrl = trackImageUrls[0];
      _audioPlayer.play();
    } catch (e) {
      print('Error playing audio queue: $e');
    }
  }

  static Future<void> resume() async {
    _audioPlayer.play();
  }

  static Future<void> pause() async {
    _audioPlayer.pause();
  }

  static Future<void> stop() async {
    _audioPlayer.stop();
  }

  static Future<void> preload(String url) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
    } catch (e) {
      print('Error preloading audio: $e');
    }
  }

  static Future<void> skipToNext() async {
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      print('Error skipping to next track: $e');
    }
  }

  static Future<void> skipToPrevious() async {
    try {
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      print('Error skipping to previous track: $e');
    }
  }

  static Stream<Duration> get positionStream => _audioPlayer.positionStream;
  static Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  static Stream<PlayerState> get playerStateStream =>
      _audioPlayer.playerStateStream;
  static Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  static Duration? get duration => _audioPlayer.duration;
  static Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  static List<String> get currentQueue =>
      _audioPlayer.sequence
          ?.map((source) => (source.tag as TrackInfo?)?.name ?? 'Unknown Track')
          .toList() ??
      [];

  static Stream<TrackInfo?> get currentTrackStream =>
      _audioPlayer.currentIndexStream.map((index) {
        if (index != null && index < _audioPlayer.sequence!.length) {
          return _audioPlayer.sequence![index].tag as TrackInfo?;
        }
        return null;
      });
}
