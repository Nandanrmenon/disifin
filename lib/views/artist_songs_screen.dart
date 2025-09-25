import 'dart:convert';

import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/album_songs_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtistSongsScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? imageUrl;

  const ArtistSongsScreen(
      {required this.artistId,
      required this.artistName,
      this.imageUrl,
      super.key});

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  List<dynamic> _albums = [];
  List<dynamic> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('url');
    final accessToken = prefs.getString('accessToken');
    _serverUrl = url;

    if (url == null || accessToken == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Missing server URL or access token.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final albumsResp = await http.get(
        Uri.parse(
            '$url/Items?ArtistIds=${widget.artistId}&IncludeItemTypes=MusicAlbum&Recursive=true'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken
        },
      );

      final songsResp = await http.get(
        Uri.parse(
            '$url/Items?ArtistIds=${widget.artistId}&IncludeItemTypes=Audio&Recursive=true'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken
        },
      );

      if (albumsResp.statusCode == 200) {
        final data = jsonDecode(albumsResp.body);
        if (data is Map && data['Items'] is List) {
          _albums = data['Items'];
        } else if (data is List) {
          _albums = data;
        }
      }

      if (songsResp.statusCode == 200) {
        final data = jsonDecode(songsResp.body);
        if (data is Map && data['Items'] is List) {
          _songs = data['Items'];
        } else if (data is List) {
          _songs = data;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching artist data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playAllSongs() async {
    if (_songs.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final server = _serverUrl ?? '';

    final List<String> urls = [];
    final List<String> names = [];
    final List<String> images = [];
    final List<String> artists = [];

    for (final s in _songs) {
      final id = s['Id'];
      urls.add('$server/Audio/$id/stream.mp3?api_key=$accessToken');
      names.add(s['Name'] ?? 'Unknown');
      images.add(s['ImageTags'] != null &&
              s['ImageTags']['Primary'] != null &&
              server.isNotEmpty
          ? '$server/Items/$id/Images/Primary?tag=${s['ImageTags']['Primary']}'
          : '');
      artists.add(widget.artistName);
    }

    await AudioPlayerService().playQueue(urls, names, images, artists);
    if (mounted) Navigator.pushNamed(context, '/fullscreen_audio_player');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(widget.artistName),
              background: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                  : null,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty ? null : _playAllSongs,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All Songs'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty
                          ? null
                          : () async {
                              final shuffled = List<dynamic>.from(_songs);
                              shuffled.shuffle();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final accessToken =
                                  prefs.getString('accessToken') ?? '';
                              final server = _serverUrl ?? '';

                              final List<String> urls = [];
                              final List<String> names = [];
                              final List<String> images = [];
                              final List<String> artists = [];

                              for (final s in shuffled) {
                                final id = s['Id'];
                                urls.add(
                                    '$server/Audio/$id/stream.mp3?api_key=$accessToken');
                                names.add(s['Name'] ?? 'Unknown');
                                images.add(s['ImageTags'] != null &&
                                        s['ImageTags']['Primary'] != null &&
                                        server.isNotEmpty
                                    ? '$server/Items/$id/Images/Primary?tag=${s['ImageTags']['Primary']}'
                                    : '');
                                artists.add(widget.artistName);
                              }

                              await AudioPlayerService()
                                  .playQueue(urls, names, images, artists);
                              if (mounted)
                                Navigator.pushNamed(
                                    context, '/fullscreen_audio_player');
                            },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle Songs'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red))),
            )
          else ...[
            if (_albums.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Albums',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            if (_albums.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final album = _albums[index];
                    final imageUrl = album['ImageTags'] != null &&
                            album['ImageTags']['Primary'] != null &&
                            _serverUrl != null
                        ? '$_serverUrl/Items/${album['Id']}/Images/Primary?tag=${album['ImageTags']['Primary']}'
                        : null;
                    return ListTile(
                      leading: imageUrl != null
                          ? Image.network(imageUrl,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Symbols.album),
                      title: Text(album['Name'] ?? 'Unknown'),
                      subtitle: Text(album['Artist'] ?? widget.artistName),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumSongsScreen(
                              albumId: album['Id'],
                              albumName: album['Name'] ?? 'Album',
                              imageUrl: imageUrl ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _albums.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Songs',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  final imageUrl = song['ImageTags'] != null &&
                          song['ImageTags']['Primary'] != null &&
                          _serverUrl != null
                      ? '$_serverUrl/Items/${song['Id']}/Images/Primary?tag=${song['ImageTags']['Primary']}'
                      : null;
                  return ListTile(
                    leading: imageUrl != null
                        ? Image.network(imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : null,
                    title: Text(song['Name'] ?? 'Unknown'),
                    subtitle: Text(song['Album'] ?? ''),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final accessToken = prefs.getString('accessToken') ?? '';
                      final server = _serverUrl ?? '';
                      final id = song['Id'];
                      final audioUrl =
                          '$server/Audio/$id/stream.mp3?api_key=$accessToken';
                      final image = imageUrl ?? '';
                      await AudioPlayerService().playTrack(audioUrl,
                          song['Name'] ?? 'Unknown', image, widget.artistName);
                      if (mounted)
                        Navigator.pushNamed(
                            context, '/fullscreen_audio_player');
                    },
                  );
                },
                childCount: _songs.length,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
