import 'dart:convert';

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackListScreen extends StatefulWidget {
  const TrackListScreen({super.key});

  @override
  _TrackListScreenState createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  List<dynamic> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;
  String? _accessToken;
  bool _isGridView = false; // Add a state variable to toggle between views

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _fetchTracks();
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

  Future<void> _fetchTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('url');
    final accessToken = prefs.getString('accessToken');
    _serverUrl = url;
    _accessToken = accessToken;

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
        Uri.parse('$url/Items?IncludeItemTypes=Audio&Recursive=true'),
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
            _tracks = data['Items'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load tracks.';
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
                  icon: Icon(
                    Symbols.play_arrow_rounded,
                  ),
                  label: const Text('Play All'),
                ),
                SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () {},
                  isSelected: false,
                  icon: Icon(Symbols.shuffle),
                ),
                Spacer(),
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
                ? const Center(
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
                            itemCount: _tracks.length,
                            itemBuilder: (context, index) {
                              final track = _tracks[index];
                              final imageUrl = track['ImageTags'] != null &&
                                      track['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${track['Id']}/Images/Primary?tag=${track['ImageTags']['Primary']}'
                                  : null;
                              final audioUrl =
                                  '$_serverUrl/Audio/${track['Id']}/stream.mp3?api_key=$_accessToken';
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  _playTrack(index);
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
                                                child: Image.network(imageUrl,
                                                    fit: BoxFit.cover),
                                              ),
                                            )
                                          : Card(
                                              child: const Icon(
                                                  Symbols.music_note,
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
                                            track['Name'] ?? 'Unknown',
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            track['Album'] ?? 'Unknown',
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
                            itemCount: _tracks.length,
                            itemBuilder: (context, index) {
                              final track = _tracks[index];
                              final imageUrl = track['ImageTags'] != null &&
                                      track['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${track['Id']}/Images/Primary?tag=${track['ImageTags']['Primary']}'
                                  : null;
                              final audioUrl =
                                  '$_serverUrl/Audio/${track['Id']}/stream.mp3?api_key=$_accessToken';
                              return ListTile(
                                leading: imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Image.network(imageUrl,
                                              fit: BoxFit.cover),
                                        ),
                                      )
                                    : const CircleAvatar(
                                        radius: 25,
                                        child: Icon(Symbols.music_note),
                                      ),
                                title: Text(
                                  track['Name'] ?? 'Unknown',
                                  maxLines: 1,
                                ),
                                subtitle: Text(track['Album'] ?? 'Unknown'),
                                onTap: () {
                                  _playTrack(index);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _playTrack(int index) {
    final List<String> urls = [];
    final List<String> trackNames = [];
    final List<String> trackImageUrls = [];
    final List<String> trackArtists = [];

    for (int i = index; i < _tracks.length; i++) {
      final track = _tracks[i];
      final audioUrl =
          '$_serverUrl/Audio/${track['Id']}/stream.mp3?api_key=$_accessToken';
      final imageUrl = track['ImageTags'] != null &&
              track['ImageTags']['Primary'] != null &&
              _serverUrl != null
          ? '$_serverUrl/Items/${track['Id']}/Images/Primary?tag=${track['ImageTags']['Primary']}'
          : '';
      final artist =
          track['ArtistItems'] != null && track['ArtistItems'].isNotEmpty
              ? track['ArtistItems'][0]['Name']
              : 'Unknown Artist';

      urls.add(audioUrl);
      trackNames.add(track['Name'] ?? 'Unknown');
      trackImageUrls.add(imageUrl);
      trackArtists.add(artist);
    }

    AudioPlayerService.playQueue(
        urls, trackNames, trackImageUrls, trackArtists);
  }
}
