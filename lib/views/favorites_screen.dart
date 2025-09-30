import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/album_songs_screen.dart';
import 'package:disifin/views/artist_songs_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  final AudioPlayerService audioPlayerService;
  const FavoritesScreen({super.key, required this.audioPlayerService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: AudioPlayerService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load liked items: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No liked items'));

          return ListView.builder(
            padding: EdgeInsets.only(bottom: 200),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              Widget leading =
                  const CircleAvatar(radius: 25, child: Icon(Icons.music_note));
              if (item.imageUrl != null) {
                leading = ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                  ),
                );
              }

              return ListTile(
                leading: leading,
                title: Text(item.name ?? 'Unknown'),
                subtitle: Text(item.artist ?? ''),
                onTap: () async {
                  final type = (item.itemType ?? '').toString().toLowerCase();

                  // Helper to build stream URL from item id when needed
                  Future<String?> buildAudioUrl() async {
                    if (item.audioUrl != null && item.audioUrl!.isNotEmpty) {
                      return item.audioUrl;
                    }
                    if (item.id == null) return null;
                    final prefs = await SharedPreferences.getInstance();
                    final server = prefs.getString('url');
                    final token = prefs.getString('accessToken');
                    if (server == null || token == null) return null;
                    return '$server/Audio/${item.id}/stream.mp3?api_key=$token';
                  }

                  if (type.contains('audio') ||
                      type.contains('track') ||
                      type.contains('song')) {
                    // Play audio items
                    final audioUrl = await buildAudioUrl();
                    if (audioUrl != null && audioUrl.isNotEmpty) {
                      await widget.audioPlayerService.playTrack(
                          audioUrl,
                          item.name ?? 'Unknown',
                          item.imageUrl ?? '',
                          item.artist ?? '');
                      if (mounted) {
                        Navigator.pushNamed(
                            context, '/fullscreen_audio_player');
                      }
                    } else {
                      // No playable url available
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Cannot play: missing stream URL')));
                      }
                    }
                  } else if (type.contains('album') ||
                      type.contains('musicalbum') ||
                      type.contains('albumfolder')) {
                    // Open album view
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumSongsScreen(
                            albumId: item.id ?? '',
                            albumName: item.name ?? 'Album',
                            imageUrl: item.imageUrl ?? '',
                          ),
                        ),
                      );
                    }
                  } else if (type.contains('artist') ||
                      type.contains('person') ||
                      type.contains('musicartist')) {
                    // Open artist view
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistSongsScreen(
                            artistId: item.id ?? '',
                            artistName: item.name ?? 'Artist',
                            imageUrl: item.imageUrl,
                          ),
                        ),
                      );
                    }
                  } else {
                    // Fallback: try to play if possible, otherwise show message
                    final audioUrl = await buildAudioUrl();
                    if (audioUrl != null && audioUrl.isNotEmpty) {
                      await widget.audioPlayerService.playTrack(
                          audioUrl,
                          item.name ?? 'Unknown',
                          item.imageUrl ?? '',
                          item.artist ?? '');
                      if (mounted) {
                        Navigator.pushNamed(
                            context, '/fullscreen_audio_player');
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Item type not supported')));
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
