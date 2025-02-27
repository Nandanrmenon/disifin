import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  _ArtistListScreenState createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  List<dynamic> _artists = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _fetchArtists();
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
        Uri.parse('$url/Items?IncludeItemTypes=Artists&Recursive=true'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : ListView.builder(
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
                                child:
                                    Image.network(imageUrl, fit: BoxFit.cover),
                              ),
                            )
                          : CircleAvatar(
                              radius: 25,
                              child: Text(artist['Name']?[0] ?? '?'),
                            ),
                      title: Text(
                        artist['Name'] ?? 'Unknown',
                        maxLines: 1,
                      ),
                    );
                  },
                ),
    );
  }
}
