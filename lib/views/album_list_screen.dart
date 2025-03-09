import 'dart:convert';

import 'package:disifin/views/album_songs_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  _AlbumListScreenState createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  List<dynamic> _albums = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _fetchAlbums();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('isGridView') ?? false;
    });
  }

  Future<void> _saveViewPreference(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGridView);
  }

  Future<void> _fetchAlbums() async {
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
        Uri.parse('$url/Items?IncludeItemTypes=MusicAlbum&Recursive=true'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _albums = data['Items'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load albums.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Symbols.play_arrow_rounded),
                    label: Text('Play All')),
                const Spacer(),
                IconButton(
                  icon: Icon(_isGridView ? Symbols.list : Symbols.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                      _saveViewPreference(_isGridView);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    year2023: false,
                  ))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red)))
                    : _isGridView
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2 / 2.5,
                            ),
                            itemCount: _albums.length,
                            itemBuilder: (context, index) {
                              final album = _albums[index];
                              final artists =
                                  (album['Artists'] as List<dynamic>?)
                                          ?.join(', ') ??
                                      'Unknown';
                              final imageUrl = album['ImageTags'] != null &&
                                      album['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${album['Id']}/Images/Primary?tag=${album['ImageTags']['Primary']}'
                                  : null;
                              print(
                                  'Album: ${album['Name']}, Image URL: $imageUrl'); // Debug print
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AlbumSongsScreen(
                                        albumId: album['Id'],
                                        albumName: album['Name'] ?? 'Unknown',
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: imageUrl != null
                                          ? Card(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      child: const Icon(
                                                          Symbols.album,
                                                          size: 50),
                                                    );
                                                  },
                                                ),
                                              ),
                                            )
                                          : Card(
                                              child: const Icon(Symbols.album,
                                                  size: 50),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            album['Name'] ?? 'Unknown',
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            artists,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: _albums.length,
                            itemBuilder: (context, index) {
                              final album = _albums[index];
                              final artists =
                                  (album['Artists'] as List<dynamic>?)
                                          ?.join(', ') ??
                                      'Unknown';
                              final imageUrl = album['ImageTags'] != null &&
                                      album['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${album['Id']}/Images/Primary?tag=${album['ImageTags']['Primary']}'
                                  : null;
                              print(
                                  'Album: ${album['Name']}, Image URL: $imageUrl'); // Debug print
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: imageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          child: SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const CircleAvatar(
                                                  radius: 25,
                                                  child: Icon(Symbols.album),
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                      : const CircleAvatar(
                                          radius: 25,
                                          child: Icon(Symbols.album),
                                        ),
                                  title: Text(
                                    album['Name'] ?? 'Unknown',
                                    maxLines: 1,
                                  ),
                                  subtitle: Text(
                                    artists,
                                    maxLines: 1,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumSongsScreen(
                                          albumId: album['Id'],
                                          albumName: album['Name'] ?? 'Unknown',
                                          imageUrl: imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
