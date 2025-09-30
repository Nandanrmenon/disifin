import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/album_list_screen.dart';
import 'package:disifin/views/album_songs_screen.dart';
import 'package:disifin/views/artist_list_screen.dart';
import 'package:disifin/views/artist_songs_screen.dart';
import 'package:disifin/views/favorites_screen.dart';
import 'package:disifin/views/track_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaListScreen extends StatefulWidget {
  final AudioPlayerService audioPlayerService;

  const MediaListScreen({super.key, required this.audioPlayerService});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  int _selectedChipIndex = 0;

  final List<String> _chipLabels = [
    'Liked',
    'Tracks',
    'Albums',
    'Artists',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(
                  _chipLabels.length,
                  (int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(_chipLabels[index]),
                        selected: _selectedChipIndex == index,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedChipIndex = selected ? index : 0;
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedChipIndex) {
      case 0:
        return _buildLiked();
      case 1:
        return _buildTracks();
      case 2:
        return _buildAlbum();
      case 3:
        return _buildArtists();
      default:
        return _buildTracks();
    }
  }

  Widget _buildTracks() {
    return TrackListScreen(audioPlayerService: widget.audioPlayerService);
  }

  Widget _buildAlbum() {
    return AlbumListScreen();
  }

  Widget _buildArtists() {
    return ArtistListScreen();
  }

  Widget _buildLiked() {
    return FavoritesScreen(audioPlayerService: widget.audioPlayerService);
  }
}
