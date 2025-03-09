import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackInfo {
  final String? name;
  final String? imageUrl;
  final String? artist; // Add artist property

  TrackInfo({this.name, this.imageUrl, this.artist});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'artist': artist,
    };
  }

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      name: json['name'],
      imageUrl: json['imageUrl'],
      artist: json['artist'],
    );
  }
}

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentTrackName;
  static String? currentTrackImageUrl;
  static final List<TrackInfo> _history = [];

  static Future<void> play(String url, String trackName, String trackImageUrl,
      String trackArtist) async {
    try {
      currentTrackName = trackName;
      currentTrackImageUrl = trackImageUrl;
      await _audioPlayer.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          album: "Album name",
          title: trackName,
          artUri: Uri.parse(trackImageUrl),
          artist: trackArtist,
        ),
      ));
      await _audioPlayer.play();
      _addToHistory(TrackInfo(
          name: trackName, imageUrl: trackImageUrl, artist: trackArtist));
      print('Added to history: $trackName'); // Debug print
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  static Future<void> playQueue(List<String> urls, List<String> trackNames,
      List<String> trackImageUrls, List<String> trackArtists) async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: List.generate(urls.length, (index) {
          return AudioSource.uri(
            Uri.parse(urls[index]),
            tag: MediaItem(
              id: urls[index],
              album: "Album name",
              title: trackNames[index],
              artUri: Uri.parse(trackImageUrls[index]),
              artist: trackArtists[index],
            ),
          );
        }),
      );
      await _audioPlayer.setAudioSource(playlist);
      currentTrackName = trackNames[0];
      currentTrackImageUrl = trackImageUrls[0];
      print('play');
      await _audioPlayer.play();
      _addToHistory(TrackInfo(
          name: trackNames[0],
          imageUrl: trackImageUrls[0],
          artist: trackArtists[0]));

      print('Added to history: ${trackNames[0]}'); // Debug print
    } catch (e) {
      print('Error playing audio queue: $e');
    }
  }

  static Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
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
      final currentTrack = await _audioPlayer.currentIndexStream.first;
      if (currentTrack != null) {
        final mediaItem = _audioPlayer.sequence![currentTrack].tag as MediaItem;
        currentTrackName = mediaItem.title;
        currentTrackImageUrl = mediaItem.artUri?.toString();
        _addToHistory(TrackInfo(
          name: mediaItem.title,
          imageUrl: mediaItem.artUri?.toString(),
          artist: mediaItem.artist,
        ));
      }
    } catch (e) {
      print('Error skipping to next track: $e');
    }
  }

  static Future<void> skipToPrevious() async {
    try {
      await _audioPlayer.seekToPrevious();
      final currentTrack = await _audioPlayer.currentIndexStream.first;
      if (currentTrack != null) {
        final mediaItem = _audioPlayer.sequence![currentTrack].tag as MediaItem;
        currentTrackName = mediaItem.title;
        currentTrackImageUrl = mediaItem.artUri?.toString();
        _addToHistory(TrackInfo(
          name: mediaItem.title,
          imageUrl: mediaItem.artUri?.toString(),
          artist: mediaItem.artist,
        ));
      }
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
          ?.map(
              (source) => (source.tag as MediaItem?)?.title ?? 'Unknown Track')
          .toList() ??
      [];

  static Stream<TrackInfo?> get currentTrackStream =>
      _audioPlayer.currentIndexStream.map((index) {
        if (index != null && index < _audioPlayer.sequence!.length) {
          final mediaItem = _audioPlayer.sequence![index].tag as MediaItem;
          return TrackInfo(
            name: mediaItem.title,
            imageUrl: mediaItem.artUri?.toString(),
            artist: mediaItem.artist,
          );
        }
        return null;
      });

  static Future<void> authenticate(
      String url, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$url/Users/AuthenticateByName'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Authorization':
              'MediaBrowser Client="Disifin", Device="Android", DeviceId="12345", Version="1.0.0"',
        },
        body: jsonEncode({
          'Username': username,
          'Pw': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['AccessToken'];

        // Save the access token and other necessary information
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('url', url);
        await prefs.setString('username', username);
      } else {
        print('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during authentication: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') != null;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('url');
    await prefs.remove('username');
  }

  static Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        jsonEncode(_history.map((track) => track.toJson()).toList());
    await prefs.setString('history', historyJson);
  }

  static Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('history');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      _history.clear();
      _history.addAll(
          historyList.map((track) => TrackInfo.fromJson(track)).toList());
    }
  }

  static void _addToHistory(TrackInfo trackInfo) {
    _history.insert(0, trackInfo);
    if (_history.length > 30) {
      _history.removeLast();
    }
    _saveHistory();
    print(
        'Current history: ${_history.map((track) => track.name).toList()}'); // Debug print
  }

  static List<TrackInfo> get history => _history;

  static List<TrackInfo> getRandomRecommendations() {
    final random = Random();
    final shuffledTracks = List<TrackInfo>.from(_history)..shuffle(random);
    return shuffledTracks.take(5).toList();
  }
}
