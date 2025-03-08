import 'dart:convert';

import 'package:disifin/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUrlValid = false;
  String? _serverName;

  Future<void> _validateUrl() async {
    final url = _urlController.text;
    setState(() {
      _isUrlValid = false;
      _serverName = null;
    });

    try {
      final response = await http.get(Uri.parse('$url/System/Info/Public'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ServerName'] != null) {
          setState(() {
            _isUrlValid = true;
            _serverName = data['ServerName'];
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('serverName', _serverName!);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = _urlController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      await AudioPlayerService.authenticate(url, username, password);
      // Handle successful login, e.g., navigate to the home page
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerLow,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading) LinearProgressIndicator(),
                Spacer(),
                Text(
                  'Disifin',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Jellyfin Music Player',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                Text('Login to your Jellyfin server'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'URL',
                        ),
                        enabled: _isUrlValid ? false : true,
                      ),
                    ),
                    if (_isUrlValid)
                      IconButton(
                          tooltip: 'Change server',
                          onPressed: () {
                            setState(() {
                              _isUrlValid = false;
                              _urlController.clear();
                              _serverName = null;
                            });
                          },
                          icon: Icon(Symbols.dns_rounded))
                  ],
                ),
                const SizedBox(height: 8),
                if (_serverName != null)
                  Text('Connected to: $_serverName',
                      style: Theme.of(context).textTheme.labelLarge),
                if (!_isUrlValid) ...[
                  ElevatedButton(
                    onPressed: _validateUrl,
                    child: const Text('Connect to Jellyfin'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_isUrlValid) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: const Text('Login'),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
