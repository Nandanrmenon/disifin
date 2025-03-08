import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _songResults = [];
  List<Map<String, String>> _albumResults = [];
  List<Map<String, String>> _artistResults = [];
  bool _isLoading = false; // Add this line

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final url = prefs.getString(
        'url'); // Assuming server URL is stored in shared preferences

    if (accessToken == null || url == null) {
      // Handle error: access token or server URL not found
      print('Error: Access token or server URL not found');
      setState(() {
        _isLoading = false; // Set loading to false
      });
      return;
    }

    print('Performing search with query: $query');
    final response = await http.get(
      Uri.parse(
          '$url/Items?searchTerm=$query&IncludeItemTypes=Audio,MusicAlbum,MusicArtist&Recursive=true'),
      headers: {
        'X-Emby-Token': accessToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Search response data: $data');
      setState(() {
        _songResults = (data['Items'] as List)
            .where((item) => item['Type'] == 'Audio')
            .map((song) => {
                  'Name': song['Name'] as String,
                  'ImageUrl': song['ImageTags'] != null &&
                          song['ImageTags']['Primary'] != null
                      ? '$url/Items/${song['Id']}/Images/Primary?token=$accessToken'
                      : ''
                })
            .toList()
            .cast<Map<String, String>>();
        _albumResults = (data['Items'] as List)
            .where((item) => item['Type'] == 'MusicAlbum')
            .map((album) => {
                  'Name': album['Name'] as String,
                  'ImageUrl': album['ImageTags'] != null &&
                          album['ImageTags']['Primary'] != null
                      ? '$url/Items/${album['Id']}/Images/Primary?token=$accessToken'
                      : ''
                })
            .toList()
            .cast<Map<String, String>>();
        _artistResults = (data['Items'] as List)
            .expand((item) => item['ArtistItems'] != null
                ? (item['ArtistItems'] as List)
                    .where((artist) => artist['Name']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .map((artist) => {
                          'Name': artist['Name'] as String,
                          'ImageUrl': artist['ImageTags'] != null &&
                                  artist['ImageTags']['Primary'] != null
                              ? '$url/Items/${artist['Id']}/Images/Primary?token=$accessToken'
                              : ''
                        })
                : [])
            .toList()
            .cast<Map<String, String>>();
        _isLoading = false; // Set loading to false
      });
    } else {
      // Handle error
      print('Error: ${response.statusCode} - ${response.body}');
      setState(() {
        _songResults = [];
        _albumResults = [];
        _artistResults = [];
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _viewAllResults(String category, List<Map<String, String>> results) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(category: category, results: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: IconButton(
                    icon: const Icon(Symbols.search),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _songResults = [];
                              _albumResults = [];
                              _artistResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: _performSearch, // Call _performSearch on text change
                onSubmitted: _performSearch,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading indicator
                  : _songResults.isEmpty &&
                          _albumResults.isEmpty &&
                          _artistResults.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.search,
                              size: 100,
                            ),
                            SizedBox(height: 16),
                            Text('Search for something.',
                                style: Theme.of(context).textTheme.labelLarge),
                          ],
                        )) // Show text if nothing is searched
                      : ListView(
                          children: [
                            if (_songResults.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Songs',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ..._songResults.take(5).map((result) => ListTile(
                                    leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: result['ImageUrl']!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: Image.network(
                                                result['ImageUrl']!,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    CircleAvatar(
                                                        child: const Icon(
                                                            Icons.music_note)),
                                              ),
                                            )
                                          : CircleAvatar(
                                              child:
                                                  const Icon(Icons.music_note)),
                                    ),
                                    title: Text(result['Name']!),
                                  )),
                              if (_songResults.length > 5)
                                ListTile(
                                  onTap: () =>
                                      _viewAllResults('Songs', _songResults),
                                  title: const Text('View All Songs'),
                                  trailing: const Icon(
                                      Symbols.arrow_right_alt_rounded),
                                ),
                            ],
                            if (_albumResults.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Albums',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ..._albumResults.take(5).map((result) => ListTile(
                                    leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: result['ImageUrl']!.isNotEmpty
                                          ? Image.network(
                                              result['ImageUrl']!,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.album),
                                            )
                                          : const Icon(Icons.album),
                                    ),
                                    title: Text(result['Name']!),
                                  )),
                              if (_albumResults.length > 5)
                                ListTile(
                                  onTap: () =>
                                      _viewAllResults('Albums', _albumResults),
                                  title: const Text('View All Albums'),
                                  trailing: const Icon(
                                      Symbols.arrow_right_alt_rounded),
                                ),
                            ],
                            if (_artistResults.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Artists',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ..._artistResults
                                  .take(5)
                                  .map((result) => ListTile(
                                        leading: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: result['ImageUrl']!.isNotEmpty
                                              ? Image.network(
                                                  result['ImageUrl']!,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      CircleAvatar(
                                                          child: const Icon(
                                                              Icons.person)),
                                                )
                                              : CircleAvatar(
                                                  child:
                                                      const Icon(Icons.person)),
                                        ),
                                        title: Text(result['Name']!),
                                      )),
                              if (_artistResults.length > 5)
                                ListTile(
                                  onTap: () => _viewAllResults(
                                      'Artists', _artistResults),
                                  title: const Text('View All Artists'),
                                  trailing: const Icon(
                                      Symbols.arrow_right_alt_rounded),
                                ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsPage extends StatelessWidget {
  final String category;
  final List<Map<String, String>> results;

  const ResultsPage({super.key, required this.category, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All $category'),
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: results[index]['ImageUrl']!.isNotEmpty
                  ? Image.network(
                      results[index]['ImageUrl']!,
                      errorBuilder: (context, error, stackTrace) =>
                          CircleAvatar(child: const Icon(Icons.music_note)),
                    )
                  : const Icon(Icons.music_note),
            ),
            title: Text(results[index]['Name']!),
          );
        },
      ),
    );
  }
}
