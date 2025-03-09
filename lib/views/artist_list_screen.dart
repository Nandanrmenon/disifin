import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  List<dynamic> _artists = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _fetchArtists();
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

  Future<void> _fetchArtists() async {
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
        setState(() {});
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$url/Items?IncludeItemTypes=MusicArtist&Recursive=true'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _artists = data['Items'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load artists.';
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                            padding: EdgeInsets.only(bottom: 200),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2 / 2.5,
                            ),
                            itemCount: _artists.length,
                            itemBuilder: (context, index) {
                              final artist = _artists[index];
                              final imageUrl = artist['ImageTags'] != null &&
                                      artist['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${artist['Id']}/Images/Primary?tag=${artist['ImageTags']['Primary']}'
                                  : null;
                              return GestureDetector(
                                onTap: () {
                                  // Handle artist tap
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
                                                          Symbols.person,
                                                          size: 50),
                                                    );
                                                  },
                                                ),
                                              ),
                                            )
                                          : Card(
                                              child: const Icon(Symbols.person,
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
                                            artist['Name'] ?? 'Unknown',
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
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
                            padding: EdgeInsets.only(bottom: 200),
                            itemCount: _artists.length,
                            itemBuilder: (context, index) {
                              final artist = _artists[index];
                              final imageUrl = artist['ImageTags'] != null &&
                                      artist['ImageTags']['Primary'] != null &&
                                      _serverUrl != null
                                  ? '$_serverUrl/Items/${artist['Id']}/Images/Primary?tag=${artist['ImageTags']['Primary']}'
                                  : null;
                              return ListTile(
                                leading: imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
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
                                                child: Icon(Symbols.person),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    : const CircleAvatar(
                                        radius: 25,
                                        child: Icon(Symbols.person),
                                      ),
                                title: Text(
                                  artist['Name'] ?? 'Unknown',
                                  maxLines: 1,
                                ),
                                onTap: () {
                                  // Handle artist tap
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
