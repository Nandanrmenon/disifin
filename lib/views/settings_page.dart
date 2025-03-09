import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _serverName;
  String? _username;

  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverName = prefs.getString('serverName');
      _username = prefs.getString('username');
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AudioPlayerService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _serverName!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _username!,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Symbols.dns_rounded, size: 48),
                  ],
                ),
              ),
            ),
          ),
          // ListTile(
          //   leading: CircleAvatar(
          //       radius: 48,
          //       backgroundColor:
          //           Theme.of(context).colorScheme.secondaryFixedDim,
          //       child: Icon(Symbols.dns_rounded)),
          //   title: Text(
          //     _serverName!,
          //     style: Theme.of(context).textTheme.titleLarge,
          //   ),
          //   subtitle: Text(
          //     _username!,
          //     style: Theme.of(context).textTheme.labelLarge,
          //   ),
          //   onTap: () {},
          // ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiaryFixedDim,
              child: const Icon(Symbols.style),
            ),
            title: const Text('Customize'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomizePage()),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: const Icon(Symbols.delete),
            ),
            title: const Text('Clear History'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Clear History'),
                  content:
                      const Text('Are you sure you want to clear the history?'),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AudioPlayerService.clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('History cleared')),
                );
              }
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              child: const Icon(Symbols.logout),
            ),
            title: const Text('Logout'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _logout(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  int _selectedSliderStyle = 1;

  @override
  void initState() {
    super.initState();
    _loadSliderStyle();
  }

  Future<void> _loadSliderStyle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSliderStyle = prefs.getInt('sliderStyle') ?? 1;
    });
  }

  Future<void> _saveSliderStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sliderStyle', style);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Customize'),
        ),
        body: ListView(
          children: [
            ListTile(
              title: Text(
                'Slider Style',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ListTile(
              title: const Text('Slider Style 1'),
              leading: Radio<int>(
                value: 1,
                groupValue: _selectedSliderStyle,
                onChanged: (value) {
                  setState(() {
                    _selectedSliderStyle = value!;
                    _saveSliderStyle(value);
                  });
                },
              ),
              onTap: () => setState(
                () {
                  _selectedSliderStyle = 1;
                  _saveSliderStyle(1);
                },
              ),
            ),
            ListTile(
              title: const Text('Slider Style 2'),
              leading: Radio<int>(
                value: 2,
                groupValue: _selectedSliderStyle,
                onChanged: (value) {
                  setState(() {
                    _selectedSliderStyle = value!;
                    _saveSliderStyle(value);
                  });
                },
              ),
              onTap: () => setState(
                () {
                  _selectedSliderStyle = 2;
                  _saveSliderStyle(2);
                },
              ),
            ),
          ],
        ));
  }
}
