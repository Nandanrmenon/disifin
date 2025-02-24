import 'package:disifin/api/jellyfin_api.dart';
import 'package:flutter/material.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  late JellyfinApi api;
  late Future<List<dynamic>> musicList;

  @override
  void initState() {
    super.initState();
    api = JellyfinApi(
        baseUrl: 'http://100.81.54.83:8096',
        apiKey: 'a246297a62354f0199e97e2d6c408878');
    musicList = api.getMusic();
    print('Fetching music from Jellyfin API...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: musicList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final music = snapshot.data!;
            print('Music fetched successfully: ${music.length} items');
            return ListView.builder(
              itemCount: music.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(music[index]['Name']),
                );
              },
            );
          }
        },
      ),
    );
  }
}
