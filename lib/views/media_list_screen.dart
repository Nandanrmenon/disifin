import 'package:disifin/views/album_list_screen.dart';
import 'package:disifin/views/artist_list_screen.dart';
import 'package:disifin/views/track_list_screen.dart';
import 'package:flutter/material.dart';

class MediaListScreen extends StatefulWidget {
  const MediaListScreen({super.key});

  @override
  _MediaListScreenState createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  int _selectedChipIndex = 0;

  final List<String> _chipLabels = ['Tracks', 'Albums', 'Artists'];

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
        return TrackListScreen();
      case 1:
        return AlbumListScreen();
      case 2:
        return _buildArtists();
      default:
        return _buildTracks();
    }
  }

  Widget _buildTracks() {
    return TrackListScreen();
  }

  Widget _buildAlbums() {
    return AlbumListScreen();
  }

  Widget _buildArtists() {
    return ArtistListScreen();
  }
}
