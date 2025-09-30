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
  final String? id;
  final String? audioUrl;
  final String? itemType;

  TrackInfo(
      {this.name,
      this.imageUrl,
      this.artist,
      this.id,
      this.audioUrl,
      this.itemType});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'id': id,
      'audioUrl': audioUrl,
      'itemType': itemType,
      'artist': artist,
    };
  }

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      name: json['name'],
      imageUrl: json['imageUrl'],
      id: json['id'],
      audioUrl: json['audioUrl'],
      itemType: json['itemType'],
      artist: json['artist'],
    );
  }
}

class AudioPlayerService extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _clientHeader =
      'MediaBrowser Client="Disifin", Device="Flutter", DeviceId="flutter_app_1", Version="1.0.0"';
  static String? currentTrackName;
  static String? currentTrackImageUrl;
  static final List<TrackInfo> _history = [];
  static Database? _database;

  late final AudioHandler _audioHandler;
  AudioPlayerService() {
    // Initialize playback state and current media item listeners so the
    // AudioHandler instance created by AudioService.init will emit states
    // and drive the platform notification.
    _audioPlayer.playbackEventStream.listen((event) {
      playbackState.add(playbackStateFromEvent(event));
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index < _audioPlayer.sequence.length) {
        final mediaItem = _audioPlayer.sequence[index].tag as MediaItem;
        _currentMediaItem = mediaItem;
        this.mediaItem.add(mediaItem); // Correctly update the mediaItem
      }
    });

    // When the audio source reports its duration update the MediaItem so the
    // platform notification can show a seekbar (it needs mediaItem.duration).
    _audioPlayer.durationStream.listen((d) {
      if (d != null && _currentMediaItem != null) {
        final updated = MediaItem(
          id: _currentMediaItem!.id,
          album: _currentMediaItem!.album,
          title: _currentMediaItem!.title,
          artUri: _currentMediaItem!.artUri,
          artist: _currentMediaItem!.artist,
          duration: d,
        );
        _currentMediaItem = updated;
        mediaItem.add(updated);
        // Also emit a playback state update so notification UI refreshes. We
        // construct a PlaybackState from the current player state instead of
        // relying on internals of the playbackEventStream.
        playbackState.add(PlaybackState(
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
        ));
      }
    });
  }

  MediaItem? _currentMediaItem;

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
        ? _audioPlayer.sequence[_audioPlayer.currentIndex!].tag as MediaItem
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

  Future<void> loadPlayerState() async {
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
      // Prepare the audio source and restore position without starting playback
      await playTrack(url, name, imageUrl, artist, play: false);
      await seekTrack(Duration(milliseconds: position));
      // Ensure paused state after restore
      await _audioPlayer.pause();
    }
  }

  Future<void> playTrack(
      String url, String trackName, String trackImageUrl, String trackArtist,
      {bool play = true}) async {
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
      if (play) {
        await _audioPlayer.play().then(
              (value) => _addToHistory(TrackInfo(
                  name: trackName,
                  imageUrl: trackImageUrl,
                  artist: trackArtist)),
            );
      }
      await _savePlayerState();
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
        final mediaItem = _audioPlayer.sequence[currentTrack].tag as MediaItem;
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
        final mediaItem = _audioPlayer.sequence[currentTrack].tag as MediaItem;
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

  static List<String> get currentQueue => _audioPlayer.sequence
      .map((source) => (source.tag as MediaItem?)?.title ?? 'Unknown Track')
      .toList();

  static Stream<TrackInfo?> get currentTrackStream =>
      _audioPlayer.currentIndexStream.map((index) {
        if (index != null && index < _audioPlayer.sequence.length) {
          final mediaItem = _audioPlayer.sequence[index].tag as MediaItem;
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
    // Adopt Jellyfin-style robust login: trim url, include ApiVersion, persist profile
    const String apiVersion = '10.11.0';
    const String clientHeader =
        'MediaBrowser Client="Disifin", Device="Flutter", DeviceId="flutter_app_1", Version="1.0.0"';

    try {
      String baseUrl = url.trim();
      if (baseUrl.endsWith('/'))
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await http.post(
        Uri.parse('$baseUrl/Users/AuthenticateByName'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Authorization': clientHeader,
        },
        body: jsonEncode({
          'Username': username,
          'Pw': password,
          'ApiVersion': apiVersion,
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['AccessToken'];
        final userId = data['User']?['Id'];

        // Save details to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken ?? '');
        await prefs.setString('url', baseUrl);
        await prefs.setString('username', username);
        if (userId != null) await prefs.setString('userId', userId);

        // fetch server info if available and save
        try {
          final sys = await http.get(Uri.parse('$baseUrl/System/Info/Public'),
              headers: {'X-Emby-Authorization': clientHeader});
          if (sys.statusCode == 200) {
            final sysData = jsonDecode(sys.body);
            final serverName = sysData['ServerName'];
            if (serverName != null)
              await prefs.setString('serverName', serverName);
          }
        } catch (_) {}

        // Persist a simple profile record so tryAutoLogin can use it later
        final profileId = _profileId(baseUrl, username);
        final profile = jsonEncode({
          'id': profileId,
          'serverUrl': baseUrl,
          'username': username,
          'password': password,
          'accessToken': accessToken,
          'userId': userId,
        });
        final profiles = prefs.getStringList('user_profiles') ?? [];
        profiles.removeWhere((p) => jsonDecode(p)['id'] == profileId);
        profiles.add(profile);
        await prefs.setStringList('user_profiles', profiles);
        await prefs.setString('current_profile_id', profileId);
      } else {
        throw Exception(
            'Authentication failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
      rethrow;
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
    // Clear current profile selection but keep saved profiles intact
    await prefs.remove('accessToken');
    await prefs.remove('url');
    await prefs.remove('username');
    await prefs.remove('userId');
    await prefs.remove('serverName');
    await prefs.remove('current_profile_id');
  }

  // Helpers for profile id and auto-login similar to nahcon's JellyfinService
  static String _profileId(String serverUrl, String username) =>
      '${serverUrl.trim()}|${username.trim()}';

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('current_profile_id');
    if (id == null) return null;
    final profiles = prefs.getStringList('user_profiles') ?? [];
    final profile = profiles
        .map((p) => jsonDecode(p))
        .firstWhere((p) => p['id'] == id, orElse: () => null);
    return profile;
  }

  static Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await getCurrentProfile();
    if (profile != null) {
      try {
        await authenticate(
            profile['serverUrl'], profile['username'], profile['password']);
        return true;
      } catch (e) {
        // failed to auto-login
        await prefs.remove('accessToken');
        return false;
      }
    }
    return false;
  }

  // Favorites support
  static Future<void> setFavorite(String itemId, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final userId = prefs.getString('userId');
    final baseUrl = prefs.getString('url');

    if (userId == null || accessToken == null || baseUrl == null) {
      debugPrint('[setFavorite] Not authenticated');
      throw Exception('Not authenticated');
    }

    // If the provided itemId looks like an audio stream URL, try to extract the server item id
    String serverItemId = itemId;
    try {
      final uri = Uri.parse(itemId);
      // Expect paths like /Audio/{id}/stream.mp3
      final segments = uri.pathSegments;
      final audioIndex = segments.indexOf('Audio');
      if (audioIndex != -1 && audioIndex + 1 < segments.length) {
        serverItemId = segments[audioIndex + 1];
      }
    } catch (_) {
      // not a url, keep as-is
    }

    final url = '$baseUrl/UserFavoriteItems/$serverItemId';
    http.Response response;
    if (isFavorite) {
      debugPrint('[setFavorite] Sending POST to add favorite: $url');
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
          'X-Emby-Authorization': _clientHeader,
        },
      );
    } else {
      debugPrint('[setFavorite] Sending DELETE to remove favorite: $url');
      response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
          'X-Emby-Authorization': _clientHeader,
        },
      );
    }

    debugPrint('[setFavorite] Response status: ${response.statusCode}');
    debugPrint('[setFavorite] Response body: ${response.body}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      debugPrint('[setFavorite] ERROR: ${response.statusCode}');
      throw Exception('Failed to update favorite: ${response.statusCode}');
    }
  }

  static Future<List<TrackInfo>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final userId = prefs.getString('userId');
    final baseUrl = prefs.getString('url');

    if (userId == null || accessToken == null || baseUrl == null) {
      throw Exception('Not authenticated');
    }

    // Request only music-related item types from the server to avoid movies/TV
    final favUri = Uri.parse(
        '$baseUrl/Users/$userId/Items?Filters=IsFavorite&Recursive=true&IncludeItemTypes=Audio,MusicAlbum,MusicArtist');
    final response = await http.get(
      favUri,
      headers: {
        'Content-Type': 'application/json',
        'X-Emby-Token': accessToken,
        'X-Emby-Authorization': _clientHeader,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['Items'] is List) {
        final rawItems = data['Items'] as List;
        // Client-side filter as a fallback in case the server returns non-music items
        final musicItems = rawItems.where((item) {
          final type = (item['Type'] ??
                  item['CollectionType'] ??
                  item['MediaType'] ??
                  '')
              .toString()
              .toLowerCase();
          return type.contains('audio') ||
              type.contains('music') ||
              type.contains('track') ||
              type.contains('album') ||
              type.contains('artist');
        }).toList();

        return musicItems.map((item) {
          final id = item['Id'] as String?;
          final image = item['ImageTags'] != null &&
                  item['ImageTags']['Primary'] != null
              ? '$baseUrl/Items/$id/Images/Primary?tag=${item['ImageTags']['Primary']}'
              : null;
          final audio = id != null
              ? '$baseUrl/Audio/$id/stream.mp3?api_key=$accessToken'
              : null;
          return TrackInfo(
            id: id,
            name: item['Name'],
            imageUrl: image,
            audioUrl: audio,
            itemType:
                item['Type'] ?? item['CollectionType'] ?? item['MediaType'],
            artist: item['AlbumArtist'] ?? item['Artist'] ?? '',
          );
        }).toList();
      }
      return [];
    }
    throw Exception('Failed to load favorites: ${response.statusCode}');
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
