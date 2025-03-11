import 'package:disifin/services/audio_player_service.dart';
import 'package:disifin/theme.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
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
                          _serverName ?? 'Unknown Server',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _username ?? 'Unknown User',
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
  Color _selectedSeedColor = Colors.red;
  DynamicSchemeVariant _selectedSchemeVariant = DynamicSchemeVariant.content;
  bool _amoledBackground = false;

  @override
  void initState() {
    super.initState();
    _loadSliderStyle();
    _loadSeedColor();
    _loadSchemeVariant();
    _loadAmoledBackground();
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

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final seedColorValue = prefs.getInt('seedColor') ?? Colors.red.value;
    setState(() {
      _selectedSeedColor = Color(seedColorValue);
    });
  }

  Future<void> _loadSchemeVariant() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeVariantValue = prefs.getInt('schemeVariant') ?? 0;
    setState(() {
      _selectedSchemeVariant = DynamicSchemeVariant.values[schemeVariantValue];
    });
  }

  Future<void> _saveSchemeVariant(DynamicSchemeVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('schemeVariant', variant.index);
    setState(() {
      _selectedSchemeVariant = variant;
    });
    context.read<ThemeNotifier>().setSchemeVariant(variant);
  }

  Future<void> _loadAmoledBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _amoledBackground = prefs.getBool('amoledBackground') ?? false;
    });
  }

  Future<void> _saveAmoledBackground(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('amoledBackground', value);
    setState(() {
      _amoledBackground = value;
    });
    context.read<ThemeNotifier>().setAmoledBackground(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Slider Style',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium!
                            .copyWith(color: Colors.white70),
                      ),
                    ),
                    ListTile(
                      title: const Text('Slider Style 1'),
                      trailing: Radio<int>(
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
                      trailing: Radio<int>(
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
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Pitch Black',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              trailing: Switch.adaptive(
                thumbIcon: WidgetStatePropertyAll(Icon(
                  Symbols.check,
                  color: Colors.white,
                )),
                value: _amoledBackground,
                onChanged: (value) {
                  _saveAmoledBackground(value);
                },
              ),
            ),
            ListTile(
              title: Text(
                'Seed Color',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                // scrollDirection: Axis.horizontal,
                alignment: WrapAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () {
                          _selectedSeedColor = Colors.red;
                          context
                              .read<ThemeNotifier>()
                              .setSeedColor(Colors.red);
                        },
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color:
                                  _selectedSeedColor.value == Colors.red.value
                                      ? Colors.white70
                                      : Colors.transparent,
                            )),
                        child: _selectedSeedColor.value == Colors.red.value
                            ? Icon(Symbols.check)
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () {
                          _selectedSeedColor = Colors.blue;
                          context
                              .read<ThemeNotifier>()
                              .setSeedColor(Colors.blue);
                        },
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color:
                                  _selectedSeedColor.value == Colors.blue.value
                                      ? Colors.white70
                                      : Colors.transparent,
                            )),
                        child: _selectedSeedColor.value == Colors.blue.value
                            ? Icon(Symbols.check)
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () {
                          _selectedSeedColor = Colors.green;
                          context
                              .read<ThemeNotifier>()
                              .setSeedColor(Colors.green);
                        },
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color:
                                  _selectedSeedColor.value == Colors.green.value
                                      ? Colors.white70
                                      : Colors.transparent,
                            )),
                        child: _selectedSeedColor.value == Colors.green.value
                            ? Icon(Symbols.check)
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () {
                          _selectedSeedColor = Colors.orange;
                          context
                              .read<ThemeNotifier>()
                              .setSeedColor(Colors.orange);
                        },
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color: _selectedSeedColor.value ==
                                      Colors.orange.value
                                  ? Colors.white70
                                  : Colors.transparent,
                            )),
                        child: _selectedSeedColor.value == Colors.orange.value
                            ? Icon(Symbols.check)
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () {
                          _selectedSeedColor = Colors.purple;
                          context
                              .read<ThemeNotifier>()
                              .setSeedColor(Colors.purple);
                        },
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color: _selectedSeedColor.value ==
                                      Colors.purple.value
                                  ? Colors.white70
                                  : Colors.transparent,
                            )),
                        child: _selectedSeedColor.value == Colors.purple.value
                            ? Icon(Symbols.check)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ListTile(
            //   title: Text(
            //     'Dynamic Scheme Variant',
            //     style: Theme.of(context).textTheme.labelLarge,
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Content'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.content,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.content;
            //       _saveSchemeVariant(DynamicSchemeVariant.content);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Expressive'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.expressive,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.expressive;
            //       _saveSchemeVariant(DynamicSchemeVariant.expressive);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Fidelity'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.fidelity,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.fidelity;
            //       _saveSchemeVariant(DynamicSchemeVariant.fidelity);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('FruitSalad'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.fruitSalad,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.fruitSalad;
            //       _saveSchemeVariant(DynamicSchemeVariant.fruitSalad);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Monochrome'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.monochrome,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.monochrome;
            //       _saveSchemeVariant(DynamicSchemeVariant.monochrome);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Neutral'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.neutral,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.neutral;
            //       _saveSchemeVariant(DynamicSchemeVariant.neutral);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Rainbow'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.rainbow,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.rainbow;
            //       _saveSchemeVariant(DynamicSchemeVariant.rainbow);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Tonal Spot'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.tonalSpot,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.tonalSpot;
            //       _saveSchemeVariant(DynamicSchemeVariant.tonalSpot);
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Vibrant'),
            //   leading: Radio<DynamicSchemeVariant>(
            //     value: DynamicSchemeVariant.vibrant,
            //     groupValue: _selectedSchemeVariant,
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedSchemeVariant = value!;
            //         _saveSchemeVariant(value);
            //       });
            //     },
            //   ),
            //   onTap: () => setState(
            //     () {
            //       _selectedSchemeVariant = DynamicSchemeVariant.vibrant;
            //       _saveSchemeVariant(DynamicSchemeVariant.vibrant);
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
