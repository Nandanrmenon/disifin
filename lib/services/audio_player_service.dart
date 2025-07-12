import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:disifin/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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

class AudioPlayerService extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentTrackName;
  static String? currentTrackImageUrl;
  static final List<TrackInfo> _history = [];
  static Database? _database;

  late final AudioHandler _audioHandler;

  AudioPlayerService();

  AudioPlayerService.initialize(this._audioHandler) {
    _audioPlayer.playbackEventStream.listen((event) {
      playbackState.add(playbackStateFromEvent(event));
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index < _audioPlayer.sequence!.length) {
        final mediaItem = _audioPlayer.sequence![index].tag as MediaItem;
        this.mediaItem.add(mediaItem); // Correctly update the mediaItem
      }
    });
  }

  PlaybackState playbackStateFromEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _audioPlayer.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_audioPlayer.processingState),
      playing: _audioPlayer.playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> skipToNext() => _audioPlayer.seekToNext();

  @override
  Future<void> skipToPrevious() => _audioPlayer.seekToPrevious();

  @override
  Future<void> stop() => _audioPlayer.stop();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    _audioPlayer.setLoopMode(
      repeatMode == AudioServiceRepeatMode.one
          ? LoopMode.one
          : repeatMode == AudioServiceRepeatMode.all
              ? LoopMode.all
              : LoopMode.off,
    );
    return super.setRepeatMode(repeatMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) {
    _audioPlayer
        .setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
    return super.setShuffleMode(shuffleMode);
  }

  static Future<void> _initDatabase() async {
    if (_database != null) return;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE cache(key TEXT PRIMARY KEY, value TEXT)',
        );
        db.execute(
          'CREATE TABLE login_credentials(id INTEGER PRIMARY KEY, username TEXT, password TEXT)',
        );
        db.execute(
          'CREATE TABLE song_history(id INTEGER PRIMARY KEY, name TEXT, imageUrl TEXT, artist TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> _savePlayerState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTrack = _audioPlayer.currentIndex != null
        ? _audioPlayer.sequence![_audioPlayer.currentIndex!].tag as MediaItem
        : null;
    if (currentTrack != null) {
      await prefs.setString('currentTrackUrl', currentTrack.id);
      await prefs.setString('currentTrackName', currentTrack.title);
      await prefs.setString(
          'currentTrackImageUrl', currentTrack.artUri?.toString() ?? '');
      await prefs.setString('currentTrackArtist', currentTrack.artist ?? '');
      await prefs.setInt(
          'currentTrackPosition', _audioPlayer.position.inMilliseconds);
      await DatabaseService.saveCache(
          'recentlyPlayedImage', currentTrack.artUri?.toString() ?? '');
    }
  }

  Future<void> loadPlayerState(AudioPlayerService audioPlayerService) async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('currentTrackUrl');
    final name = prefs.getString('currentTrackName');
    final imageUrl = prefs.getString('currentTrackImageUrl');
    final artist = prefs.getString('currentTrackArtist');
    final position = prefs.getInt('currentTrackPosition');

    if (url != null &&
        name != null &&
        imageUrl != null &&
        artist != null &&
        position != null) {
      await playTrack(url, name, imageUrl, artist);
      await seekTrack(Duration(milliseconds: position));
      await pausePlayback(); // Ensure the player is paused initially
    }
  }

  Future<void> playTrack(String url, String trackName, String trackImageUrl,
      String trackArtist) async {
    try {
      currentTrackName = trackName;
      currentTrackImageUrl = trackImageUrl;
      final mediaItem = MediaItem(
        id: url,
        album: "Album name",
        title: trackName,
        artUri: Uri.parse(trackImageUrl),
        artist: trackArtist,
        duration: duration,
      );
      this.mediaItem.add(mediaItem); // Correctly update the mediaItem

      await _audioPlayer.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        tag: mediaItem,
      ));
      await _audioPlayer.play().then(
            (value) => _addToHistory(TrackInfo(
                name: trackName, imageUrl: trackImageUrl, artist: trackArtist)),
          );
      _savePlayerState();
      debugPrint('Added to history: $trackName'); // Debug print
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> playQueue(List<String> urls, List<String> trackNames,
      List<String> trackImageUrls, List<String> trackArtists) async {
    try {
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: List.generate(urls.length, (index) {
          final mediaItem = MediaItem(
            id: urls[index],
            album: "Album name",
            title: trackNames[index],
            artUri: Uri.parse(trackImageUrls[index]),
            artist: trackArtists[index],
            duration: duration,
          );
          return AudioSource.uri(
            Uri.parse(urls[index]),
            tag: mediaItem,
          );
        }),
      );
      await _audioPlayer.setAudioSource(playlist);
      currentTrackName = trackNames[0];
      currentTrackImageUrl = trackImageUrls[0];

      // Notify AudioService of the first MediaItem
      final firstMediaItem = MediaItem(
        id: urls[0],
        album: "Album name",
        title: trackNames[0],
        artUri: Uri.parse(trackImageUrls[0]),
        artist: trackArtists[0],
        duration: duration,
      );
      mediaItem.add(firstMediaItem); // Correctly update the mediaItem

      debugPrint('play');
      await _audioPlayer.play().then(
            (value) => _addToHistory(TrackInfo(
                name: trackNames[0],
                imageUrl: trackImageUrls[0],
                artist: trackArtists[0])),
          );

      debugPrint('Added to history: ${trackNames[0]}'); // Debug print
    } catch (e) {
      debugPrint('Error playing audio queue: $e');
    }
  }

  static Future<void> resume() async {
    try {
      await _audioPlayer.play();
      _savePlayerState();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  static Future<void> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      _savePlayerState();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  static Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _savePlayerState();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  static Future<void> preload(String url) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
    } catch (e) {
      debugPrint('Error preloading audio: $e');
    }
  }

  static Future<void> skipToNextTrack() async {
    try {
      await _audioPlayer.seekToNext();
      final currentTrack = await _audioPlayer.currentIndexStream.first;
      if (currentTrack != null) {
        final mediaItem = _audioPlayer.sequence![currentTrack].tag as MediaItem;
        currentTrackName = mediaItem.title;
        currentTrackImageUrl = mediaItem.artUri?.toString();

        _audioPlayer.play().then(
              (value) => _addToHistory(TrackInfo(
                name: mediaItem.title,
                imageUrl: mediaItem.artUri?.toString(),
                artist: mediaItem.artist,
              )),
            );
      }
    } catch (e) {
      debugPrint('Error skipping to next track: $e');
    }
  }

  static Future<void> skipToPreviousPlayback() async {
    try {
      await _audioPlayer.seekToPrevious();
      final currentTrack = await _audioPlayer.currentIndexStream.first;
      if (currentTrack != null) {
        final mediaItem = _audioPlayer.sequence![currentTrack].tag as MediaItem;
        currentTrackName = mediaItem.title;
        currentTrackImageUrl = mediaItem.artUri?.toString();
        _audioPlayer.play().then(
              (value) => _addToHistory(TrackInfo(
                name: mediaItem.title,
                imageUrl: mediaItem.artUri?.toString(),
                artist: mediaItem.artist,
              )),
            );
      }
    } catch (e) {
      debugPrint('Error skipping to previous track: $e');
    }
  }

  static Stream<Duration> get positionStream => _audioPlayer.positionStream;
  static Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  static Stream<PlayerState> get playerStateStream =>
      _audioPlayer.playerStateStream;
  static Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  static Duration? get duration => _audioPlayer.duration;
  static Future<void> seekTrack(Duration position) async {
    await _audioPlayer.seek(position);
    _savePlayerState();
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

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['AccessToken'];

        // Save the access token and other necessary information
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('url', url);
        await prefs.setString('username', username);
      } else {
        debugPrint('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
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
    await DatabaseService.clearSongHistory();
    for (var track in _history) {
      await DatabaseService.saveSongHistory(track);
    }
  }

  static Future<void> loadHistory() async {
    _history.clear();
    _history.addAll(await DatabaseService.loadSongHistory());
  }

  static void _addToHistory(TrackInfo trackInfo) {
    // Remove the track if it already exists in the history
    _history.removeWhere((track) =>
        track.name == trackInfo.name && track.artist == trackInfo.artist);
    // Insert the track at the top of the history
    _history.insert(0, trackInfo);
    if (_history.length > 30) {
      _history.removeLast();
    }
    _saveHistory();
    debugPrint(
        'Current history: ${_history.map((track) => track.name).toList()}'); // Debug print
  }

  static List<TrackInfo> get history => _history;

  static List<TrackInfo> getRandomRecommendations() {
    final random = Random();
    final shuffledTracks = List<TrackInfo>.from(_history)..shuffle(random);
    return shuffledTracks.take(10).toList();
  }

  static Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  static Future<void> saveCache(String key, String value) async {
    await DatabaseService.saveCache(key, value);
  }

  static Future<String?> loadCache(String key) async {
    return await DatabaseService.loadCache(key);
  }

  static Future<void> clearCache(String key) async {
    await DatabaseService.clearCache(key);
  }

  static Future<void> saveLoginCredentials(
      String username, String password) async {
    await DatabaseService.saveLoginCredentials(username, password);
  }

  static Future<Map<String, String>?> loadLoginCredentials() async {
    return await DatabaseService.loadLoginCredentials();
  }

  static Future<void> clearLoginCredentials() async {
    await DatabaseService.clearLoginCredentials();
  }

  static Future<void> saveSongHistory(TrackInfo trackInfo) async {
    await DatabaseService.saveSongHistory(trackInfo);
  }

  static Future<List<TrackInfo>> loadSongHistory() async {
    return await DatabaseService.loadSongHistory();
  }

  static Future<void> clearSongHistory() async {
    await DatabaseService.clearSongHistory();
  }

  static Future<List<TrackInfo>> getRecentlyAddedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('url');
    final accessToken = prefs.getString('accessToken');

    if (url == null || accessToken == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            // '$url/Items?IncludeItemTypes=Music&SortBy=DateCreated&SortOrder=Descending&Limit=5'),
            '$url/Items?IncludeItemTypes=Audio&Recursive=true&SortBy=DateCreated&SortOrder=Descending&Limit=5'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['Items'] as List<dynamic>;
        return items.map((item) {
          return TrackInfo(
            name: item['Name'],
            imageUrl: item['ImageTags'] != null &&
                    item['ImageTags']['Primary'] != null
                ? '$url/Items/${item['Id']}/Images/Primary?tag=${item['ImageTags']['Primary']}'
                : null,
            artist: item['AlbumArtist'],
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching recently added songs: $e');
      return [];
    }
  }
}
