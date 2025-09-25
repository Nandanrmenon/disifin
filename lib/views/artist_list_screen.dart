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
        setState(() {
          _errorMessage = 'Missing server URL or access token. Please login.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Use the AlbumArtists endpoint to retrieve album artists
      final response = await http.get(
        Uri.parse('$url/Artists/AlbumArtists'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Token': accessToken,
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // AlbumArtists endpoint typically returns an object with Items or an array directly.
        List<dynamic> items;
        if (data is Map && data['Items'] is List) {
          items = data['Items'];
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }

        if (items.isNotEmpty) {
          if (mounted) {
            setState(() {
              _artists = items;
            });
          }
        } else {
          final snippet = response.body.length > 300
              ? '${response.body.substring(0, 300)}...'
              : response.body;
          if (mounted) {
            setState(() {
              _errorMessage =
                  'No album artists found. Response snippet:\n$snippet';
            });
          }
        }
      } else {
        final snippet = response.body.length > 300
            ? '${response.body.substring(0, 300)}...'
            : response.body;
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load artists: HTTP ${response.statusCode}. Response snippet:\n$snippet';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while fetching artists: $e';
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
                                  // Show raw artist JSON for debugging
                                  final pretty =
                                      const JsonEncoder.withIndent('  ')
                                          .convert(artist);
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(artist['Name'] ?? 'Artist'),
                                      content: SingleChildScrollView(
                                        child: Text(pretty),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
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
                                  // Show raw artist JSON for debugging
                                  final pretty =
                                      const JsonEncoder.withIndent('  ')
                                          .convert(artist);
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(artist['Name'] ?? 'Artist'),
                                      content: SingleChildScrollView(
                                        child: Text(pretty),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
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
