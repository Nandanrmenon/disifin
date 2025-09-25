import 'dart:convert';

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumSongsScreen extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String imageUrl;

  const AlbumSongsScreen(
      {required this.albumId,
      required this.albumName,
      required this.imageUrl,
      super.key});

  @override
  State<AlbumSongsScreen> createState() => _AlbumSongsScreenState();
}

class _AlbumSongsScreenState extends State<AlbumSongsScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;
  String? _albumArtUrl;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _fetchAlbumArt();
  }

  Future<void> _fetchSongs() async {
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
          _errorMessage = 'Missing URL or access token.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$url/Items?ParentId=${widget.albumId}&IncludeItemTypes=Audio&Recursive=true'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _songs = data['Items'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load songs.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAlbumArt() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('url');
    _serverUrl = url;

    if (url != null && Uri.tryParse(url)?.hasAbsolutePath == true) {
      setState(() {
        _albumArtUrl = '$_serverUrl/Items/${widget.albumId}/Images/Primary';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(widget.albumName),
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageUrl.isNotEmpty)
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).primaryColor,
                          child: Center(
                            child: Text(
                              widget.albumName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else if (_albumArtUrl != null && _albumArtUrl!.isNotEmpty)
                    Image.network(
                      _albumArtUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).primaryColor,
                          child: Center(
                            child: Text(
                              widget.albumName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text(
                          widget.albumName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final accessToken =
                                  prefs.getString('accessToken') ?? '';
                              final server = _serverUrl ?? '';

                              final List<String> urls = [];
                              final List<String> trackNames = [];
                              final List<String> trackImageUrls = [];
                              final List<String> trackArtists = [];

                              for (final song in _songs) {
                                final id = song['Id'];
                                final audioUrl =
                                    '$server/Audio/$id/stream.mp3?api_key=$accessToken';
                                final imageUrl = song['ImageTags'] != null &&
                                        song['ImageTags']['Primary'] != null &&
                                        server.isNotEmpty
                                    ? '$server/Items/$id/Images/Primary?tag=${song['ImageTags']['Primary']}'
                                    : '';
                                final artist = song['AlbumArtist'] ??
                                    (song['ArtistItems'] != null &&
                                            song['ArtistItems'].isNotEmpty
                                        ? song['ArtistItems'][0]['Name']
                                        : 'Unknown Artist');

                                urls.add(audioUrl);
                                trackNames.add(song['Name'] ?? 'Unknown');
                                trackImageUrls.add(imageUrl);
                                trackArtists.add(artist);
                              }

                              await AudioPlayerService().playQueue(urls,
                                  trackNames, trackImageUrls, trackArtists);

                              // Open fullscreen player to show now playing
                              if (mounted) {
                                Navigator.pushNamed(
                                    context, '/fullscreen_audio_player');
                              }
                            },
                      icon: Icon(Symbols.play_arrow),
                      label: Text('Play All'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty
                          ? null
                          : () async {
                              // Shuffle and play
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final accessToken =
                                  prefs.getString('accessToken') ?? '';
                              final server = _serverUrl ?? '';

                              final shuffled = List<dynamic>.from(_songs);
                              shuffled.shuffle();

                              final List<String> urls = [];
                              final List<String> trackNames = [];
                              final List<String> trackImageUrls = [];
                              final List<String> trackArtists = [];

                              for (final song in shuffled) {
                                final id = song['Id'];
                                final audioUrl =
                                    '$server/Audio/$id/stream.mp3?api_key=$accessToken';
                                final imageUrl = song['ImageTags'] != null &&
                                        song['ImageTags']['Primary'] != null &&
                                        server.isNotEmpty
                                    ? '$server/Items/$id/Images/Primary?tag=${song['ImageTags']['Primary']}'
                                    : '';
                                final artist = song['AlbumArtist'] ??
                                    (song['ArtistItems'] != null &&
                                            song['ArtistItems'].isNotEmpty
                                        ? song['ArtistItems'][0]['Name']
                                        : 'Unknown Artist');

                                urls.add(audioUrl);
                                trackNames.add(song['Name'] ?? 'Unknown');
                                trackImageUrls.add(imageUrl);
                                trackArtists.add(artist);
                              }

                              await AudioPlayerService().playQueue(urls,
                                  trackNames, trackImageUrls, trackArtists);

                              if (mounted) {
                                Navigator.pushNamed(
                                    context, '/fullscreen_audio_player');
                              }
                            },
                      icon: Icon(Symbols.shuffle),
                      label: Text('Shuffle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    title: Text(song['Name'] ?? 'Unknown'),
                    subtitle: Text(song['AlbumArtist'] ?? 'Unknown Artist'),
                    trailing: Icon(Symbols.more_vert),
                  );
                },
                childCount: _songs.length,
              ),
            ),
        ],
      ),
    );
  }
}
