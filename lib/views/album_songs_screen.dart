import 'dart:convert';

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
              centerTitle: false,
              title: Text(widget.albumName),
              titlePadding: const EdgeInsets.only(left: 56.0, bottom: 14.0),
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
                      // onPressed: () async {
                      //   // Play all songs
                      //   for (var song in _songs) {
                      //     await AudioPlayerService.play(
                      //       song['Id'],
                      //       song['Name'],
                      //       song['AlbumArtist'],
                      //       _serverUrl!,
                      //     );
                      //   }
                      //   Navigator.pushNamed(context, '/fullscreen_audio_player',
                      //       arguments: {
                      //         'trackId': _songs.first['Id'],
                      //         'trackName': _songs.first['Name'],
                      //         'trackArtist': _songs.first['AlbumArtist'],
                      //       });
                      // },
                      onPressed: () {},
                      icon: Icon(Symbols.play_arrow),
                      label: Text('Play All'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      // onPressed: () async {
                      //   // Shuffle and play songs
                      //   _songs.shuffle();
                      //   for (var song in _songs) {
                      //     await AudioPlayerService.play(
                      //       song['Id'],
                      //       song['Name'],
                      //       song['AlbumArtist'],
                      //       _serverUrl!,
                      //     );
                      //   }
                      //   Navigator.pushNamed(context, '/fullscreen_audio_player',
                      //       arguments: {
                      //         'trackId': _songs.first['Id'],
                      //         'trackName': _songs.first['Name'],
                      //         'trackArtist': _songs.first['AlbumArtist'],
                      //       });
                      // },
                      icon: Icon(Symbols.shuffle),
                      label: Text('Shuffle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _songs[index];
                return ListTile(
                  title: Text(song['Name'] ?? 'Unknown'),
                  subtitle: Text(song['AlbumArtist'] ?? 'Unknown Artist'),
                  trailing: Icon(Symbols.more_vert),
                  // onTap: () async {
                  //   try {
                  //     await AudioPlayerService.play(
                  //       song['Id'],
                  //       song['Name'],
                  //       song['AlbumArtist'],
                  //       _serverUrl!,
                  //     );
                  //     Navigator.pushNamed(context, '/fullscreen_audio_player',
                  //         arguments: {
                  //           'trackId': song['Id'],
                  //           'trackName': song['Name'],
                  //           'trackArtist': song['AlbumArtist'],
                  //         });
                  //   } catch (e) {
                  //     print('Error playing audio: $e');
                  //   }
                  // },
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
