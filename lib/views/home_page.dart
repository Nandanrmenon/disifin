import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await AudioPlayerService.loadHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = AudioPlayerService.history.length > 5
        ? AudioPlayerService.getRandomRecommendations()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Symbols.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (AudioPlayerService.history.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 200),
                  Container(
                      decoration: BoxDecoration(),
                      child: Icon(Symbols.music_note, size: 100)),
                  const SizedBox(height: 16),
                  Text(
                    'Start playing some music',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (AudioPlayerService.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Recently Played',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (AudioPlayerService.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AudioPlayerService.history.length,
                  itemBuilder: (context, index) {
                    final trackInfo = AudioPlayerService.history[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trackInfo.imageUrl != null &&
                              trackInfo.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                trackInfo.imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 100,
                              height: 100,
                              color: Theme.of(context).canvasColor,
                              child: const Icon(Symbols.music_note, size: 50),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              (trackInfo.name ?? 'Unknown Track').length > 16
                                  ? '${(trackInfo.name ?? 'Unknown Track').substring(0, 16)}...'
                                  : trackInfo.name ?? 'Unknown Track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          if (recommendations.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (recommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final trackInfo = recommendations[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trackInfo.imageUrl != null &&
                              trackInfo.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                trackInfo.imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 100,
                              height: 100,
                              color: Theme.of(context).canvasColor,
                              child: const Icon(Symbols.music_note, size: 50),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              (trackInfo.name ?? 'Unknown Track').length > 16
                                  ? '${(trackInfo.name ?? 'Unknown Track').substring(0, 16)}...'
                                  : trackInfo.name ?? 'Unknown Track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
