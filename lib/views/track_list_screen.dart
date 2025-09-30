import 'dart:convert';
import 'dart:ui';

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackListScreen extends StatefulWidget {
  final AudioPlayerService audioPlayerService;

  const TrackListScreen({super.key, required this.audioPlayerService});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  final List<dynamic> _tracks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _serverUrl;
  String? _accessToken;
  bool _isGridView = false; // Add a state variable to toggle between views
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  String _sortOption = 'A-Z'; // Add a state variable for sorting
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchTracks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('isGridView') ?? false;
      _sortOption = prefs.getString('sortOption') ?? 'A-Z';
    });
  }

  Future<void> _saveViewPreference(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGridView);
  }

  Future<void> _saveSortPreference(String sortOption) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortOption', sortOption);
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
        Uri.parse(
            '$url/Items?IncludeItemTypes=Audio&Recursive=true&StartIndex=${(_currentPage - 1) * _pageSize}&Limit=$_pageSize&SortBy=${_sortOption == 'A-Z' ? 'Name' : 'DateCreated'}&SortOrder=${_sortOption == 'Date Added (Descending)' ? 'Descending' : 'Ascending'}'),
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
            _tracks.addAll(data['Items']);
            _currentPage++;
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
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      _fetchTracks();
    }

    final currentScrollOffset = _scrollController.position.pixels;
    if (currentScrollOffset > _lastScrollOffset + 15) {
      if (_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = false;
        });
      }
    } else if (currentScrollOffset < _lastScrollOffset - 15) {
      if (!_isAppBarVisible) {
        setState(() {
          _isAppBarVisible = true;
        });
      }
    }
    _lastScrollOffset = currentScrollOffset;
  }

  void _playAllTracks() {
    final List<String> urls = [];
    final List<String> trackNames = [];
    final List<String> trackImageUrls = [];
    final List<String> trackArtists = [];

    for (final track in _tracks) {
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

    widget.audioPlayerService.playQueue(
      urls,
      trackNames,
      trackImageUrls,
      trackArtists,
    );
  }

  void _showSortOptions(BuildContext context) {
    Navigator.of(context).push(
      CupertinoModalPopupRoute(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        builder: (context) {
          return SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: const Text('A-Z'),
                      selected: _sortOption == 'A-Z',
                      onTap: () {
                        setState(() {
                          _sortOption = 'A-Z';
                          _tracks.clear();
                          _currentPage = 1;
                          _fetchTracks();
                          _saveSortPreference(_sortOption);
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortOption == 'A-Z'
                          ? Icon(Symbols.check_circle_filled, fill: 1)
                          : null,
                    ),
                    ListTile(
                      title: const Text('Date Added (Ascending)'),
                      selected: _sortOption == 'Date Added (Ascending)',
                      onTap: () {
                        setState(() {
                          _sortOption = 'Date Added (Ascending)';
                          _tracks.clear();
                          _currentPage = 1;
                          _fetchTracks();
                          _saveSortPreference(_sortOption);
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortOption == 'Date Added (Ascending)'
                          ? Icon(Symbols.check_circle_filled, fill: 1)
                          : null,
                    ),
                    ListTile(
                      title: const Text('Date Added (Descending)'),
                      selected: _sortOption == 'Date Added (Descending)',
                      onTap: () {
                        setState(() {
                          _sortOption = 'Date Added (Descending)';
                          _tracks.clear();
                          _currentPage = 1;
                          _fetchTracks();
                          _saveSortPreference(_sortOption);
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortOption == 'Date Added (Descending)'
                          ? Icon(Symbols.check_circle_filled, fill: 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: screenWidth > 600 ? 600 : screenWidth),
          child: Column(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _isAppBarVisible ? kToolbarHeight : 0.0,
                child: _isAppBarVisible
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _playAllTracks,
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
                              icon: Icon(Icons.sort_by_alpha),
                              onPressed: () => _showSortOptions(context),
                            ),
                            IconButton(
                              icon: Icon(_isGridView
                                  ? Symbols.list
                                  : Symbols.grid_view),
                              onPressed: () {
                                setState(() {
                                  _isGridView = !_isGridView;
                                  _saveViewPreference(_isGridView);
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
              ),
              Expanded(
                child: _isLoading && _tracks.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoadingMore) {
                                setState(() {
                                  _isLoadingMore = true;
                                });
                                _fetchTracks();
                              }
                              return false;
                            },
                            child: _isGridView
                                ? GridView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.only(bottom: 200),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: screenWidth > 600
                                          ? (screenWidth > 700 ? 4 : 3)
                                          : 2,
                                      childAspectRatio: screenWidth > 600
                                          ? (screenWidth > 700
                                              ? 0.5 / .75
                                              : 3 / 3.5)
                                          : 2 / 2.5,
                                    ),
                                    itemCount: _tracks.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == _tracks.length) {
                                        return _isLoadingMore
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : SizedBox.shrink();
                                      }
                                      final track = _tracks[index];
                                      final imageUrl = track['ImageTags'] !=
                                                  null &&
                                              track['ImageTags']['Primary'] !=
                                                  null &&
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
                                                      child: ClipOval(
                                                        child: Image.network(
                                                            imageUrl,
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    track['Name'] ?? 'Unknown',
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
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
                                    controller: _scrollController,
                                    itemCount: _tracks.length + 1,
                                    padding: EdgeInsets.only(bottom: 200),
                                    itemBuilder: (context, index) {
                                      if (index == _tracks.length) {
                                        return _isLoadingMore
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : SizedBox.shrink();
                                      }
                                      final track = _tracks[index];
                                      final imageUrl = track['ImageTags'] !=
                                                  null &&
                                              track['ImageTags']['Primary'] !=
                                                  null &&
                                              _serverUrl != null
                                          ? '$_serverUrl/Items/${track['Id']}/Images/Primary?tag=${track['ImageTags']['Primary']}'
                                          : null;
                                      final audioUrl =
                                          '$_serverUrl/Audio/${track['Id']}/stream.mp3?api_key=$_accessToken';
                                      return ListTile(
                                        leading: imageUrl != null
                                            ? ClipOval(
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
                                        subtitle:
                                            Text(track['Album'] ?? 'Unknown'),
                                        onTap: () {
                                          _playTrack(index);
                                        },
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          ),
        ),
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

    widget.audioPlayerService.playQueue(
      urls,
      trackNames,
      trackImageUrls,
      trackArtists,
    );
  }
}
