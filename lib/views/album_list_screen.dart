import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    final artists =
                        (album['Artists'] as List<dynamic>?)?.join(', ') ??
                            'Unknown';
                    final imageUrl = album['ImageTags'] != null &&
                            album['ImageTags']['Primary'] != null &&
                            _serverUrl != null
                        ? '$_serverUrl/Items/${album['Id']}/Images/Primary?tag=${album['ImageTags']['Primary']}'
                        : null;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
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
                                child: Icon(Symbols.album),
                              ),
                        title: Text(
                          album['Name'] ?? 'Unknown',
                          maxLines: 1,
                        ),
                        subtitle: Text(artists),
                      ),
                    );
                  },
                ),
    );
  }
}
