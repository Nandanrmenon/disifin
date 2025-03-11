import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/views/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _serverName;
  String? _username;
  List<TrackInfo> _recentlyAddedSongs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadRecentlyAddedSongs();
    getPrefs();
  }

  Future<void> _loadHistory() async {
    await AudioPlayerService.loadHistory();
    setState(() {});
  }

  Future<void> _loadRecentlyAddedSongs() async {
    final recentlyAddedSongs = await AudioPlayerService.getRecentlyAddedSongs();
    setState(() {
      _recentlyAddedSongs = recentlyAddedSongs.take(5).toList();
    });
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverName = prefs.getString('serverName');
      _username = prefs.getString('username');
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = AudioPlayerService.history.length > 5
        ? AudioPlayerService.getRandomRecommendations()
        : [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                Color.fromARGB(0, 0, 0, 0),
              ],
              begin: Alignment(0.0, -0.5),
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreetingMessage(),
                        ),
                        Text(
                          _username ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Symbols.person),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: EdgeInsets.only(bottom: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (kReleaseMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Symbols.warning, size: 48, color: Colors.orange),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Developer Note',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(
                                  'This is a work in progress. Some features may not work as expected.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height / 4),
                    child: CarouselView.weighted(
                        flexWeights: const <int>[7, 1],
                        itemSnapping: true,
                        children: recommendations.map(
                          (e) {
                            return HeroLayoutCard(
                              artist: e.artist!,
                              name: e.name!,
                              imgUrl: e.imageUrl!,
                            );
                          },
                        ).toList()),
                  ),
                ),
              if (AudioPlayerService.history.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Recently Played',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Spacer(),
                      if (AudioPlayerService.history.length >= 6)
                        TextButton(
                          onPressed: () {
                            // Navigate to the full history screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullHistoryScreen(),
                              ),
                            );
                          },
                          child: Text('View All'),
                        ),
                    ],
                  ),
                ),
              if (AudioPlayerService.history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4 / 1.5,
                    ),
                    // scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: AudioPlayerService.history.length > 6
                        ? 6
                        : AudioPlayerService.history.length,
                    itemBuilder: (context, index) {
                      if (index >= AudioPlayerService.history.length) {
                        return SizedBox.shrink();
                      }
                      final trackInfo = AudioPlayerService.history[index];
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  width: 2,
                                  strokeAlign: 1.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                              // color: Theme.of(context).colorScheme.primaryFixed,
                              borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (trackInfo.imageUrl != null &&
                                  trackInfo.imageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    trackInfo.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      borderRadius: BorderRadius.circular(10)),
                                  child:
                                      const Icon(Symbols.music_note, size: 50),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    (trackInfo.name ?? 'Unknown Track').length >
                                            10
                                        ? '${(trackInfo.name ?? 'Unknown Track').substring(0, 10)}...'
                                        : trackInfo.name ?? 'Unknown Track',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      // fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(
                height: 8,
              ),
              if (_recentlyAddedSongs.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Text(
                    'Recently Added',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              if (_recentlyAddedSongs.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height / 5),
                    child: CarouselView.weighted(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        flexWeights: const <int>[4, 2, 1],
                        itemSnapping: true,
                        children: _recentlyAddedSongs.map(
                          (e) {
                            return HeroLayoutCard(
                              artist: e.artist!,
                              name: e.name!,
                              imgUrl: e.imageUrl!,
                            );
                          },
                        ).toList()),
                  ),
                ),
              if (AudioPlayerService.history.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                    ),
                    Container(
                        decoration: BoxDecoration(),
                        child: Icon(Symbols.music_note, size: 100)),
                    const SizedBox(height: 16),
                    Text(
                      'Start playing some music',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

class HeroLayoutCard extends StatelessWidget {
  final String artist;
  final String name;
  final String? imgUrl;

  const HeroLayoutCard(
      {super.key, required this.artist, this.imgUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              image: NetworkImage(imgUrl!),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(0, 0, 0, 0),
                Color.fromARGB(154, 0, 0, 0),
              ],
              begin: Alignment(0.0, -0.5),
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FullHistoryScreen extends StatelessWidget {
  const FullHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: ListView.builder(
        itemCount: AudioPlayerService.history.length,
        itemBuilder: (context, index) {
          if (index >= AudioPlayerService.history.length) {
            return SizedBox.shrink();
          }
          final trackInfo = AudioPlayerService.history[index];
          return ListTile(
            leading:
                trackInfo.imageUrl != null && trackInfo.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          trackInfo.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const CircleAvatar(
                        radius: 25,
                        child: Icon(Symbols.music_note),
                      ),
            title: Text(trackInfo.name ?? 'Unknown Track'),
            subtitle: Text(trackInfo.artist ?? 'Unknown Artist'),
          );
        },
      ),
    );
  }
}
