import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentTrackName;
  static String? currentTrackImageUrl;

  static Future<void> play(
      String url, String trackName, String trackImageUrl) async {
    try {
      currentTrackName = trackName;
      currentTrackImageUrl = trackImageUrl;
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
      _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
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
}
