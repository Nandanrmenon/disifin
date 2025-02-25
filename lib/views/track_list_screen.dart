import 'dart:convert';

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    _fetchTracks();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
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
                                child:
                                    Image.network(imageUrl, fit: BoxFit.cover),
                              ),
                            )
                          : const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.music_note),
                            ),
                      title: Text(
                        track['Name'] ?? 'Unknown',
                        maxLines: 1,
                      ),
                      subtitle: Text(track['Album'] ?? 'Unknown'),
                      onTap: () {
                        final List<String> urls = [];
                        final List<String> trackNames = [];
                        final List<String> trackImageUrls = [];

                        for (int i = index; i < _tracks.length; i++) {
                          final track = _tracks[i];
                          final audioUrl =
                              '$_serverUrl/Audio/${track['Id']}/stream.mp3?api_key=$_accessToken';
                          final imageUrl = track['ImageTags'] != null &&
                                  track['ImageTags']['Primary'] != null &&
                                  _serverUrl != null
                              ? '$_serverUrl/Items/${track['Id']}/Images/Primary?tag=${track['ImageTags']['Primary']}'
                              : '';

                          urls.add(audioUrl);
                          trackNames.add(track['Name'] ?? 'Unknown');
                          trackImageUrls.add(imageUrl);
                        }

                        AudioPlayerService.playQueue(
                            urls, trackNames, trackImageUrls);
                      },
                    );
                  },
                ),
    );
  }
}
