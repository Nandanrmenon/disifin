import 'package:disifin/views/album_list_screen.dart';
import 'package:disifin/views/artist_list_screen.dart';
import 'package:disifin/views/track_list_screen.dart';
import 'package:flutter/material.dart';

class MediaListScreen extends StatelessWidget {
  const MediaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          automaticallyImplyLeading: false, // Remove back button
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tracks'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TrackListScreen(),
            AlbumListScreen(),
            ArtistListScreen(),
          ],
        ),
      ),
    );
  }
}
