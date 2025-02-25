import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = _urlController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('$url/Users/AuthenticateByName'),
        headers: {
          'Content-Type': 'application/json',
          'X-Emby-Authorization':
              'MediaBrowser Client="Disifin", Device="FlutterApp", DeviceId="12345", Version="1.0.0"',
        },
        body: jsonEncode({
          'Username': username,
          'Pw': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['AccessToken'];

        // Save login information
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('url', url);
        await prefs.setString('username', username);
        await prefs.setString('accessToken', accessToken);

        // Handle successful login, e.g., navigate to the home page
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
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
            colors: [const Color(0xFF3F3F3F), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 60,
                        left: 50,
                        child: Icon(Icons.music_note,
                            size: 28, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 100,
                        left: 180,
                        child: Icon(Icons.headset,
                            size: 108, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 150,
                        left: 100,
                        child: Icon(Icons.album,
                            size: 48, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 250,
                        left: 50,
                        child: Icon(Icons.library_music,
                            size: 48, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 250,
                        left: 150,
                        child: Icon(Icons.audiotrack,
                            size: 48, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 210,
                        left: 250,
                        child: Icon(Icons.album,
                            size: 78, color: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
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
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              FilledButton(
                onPressed: _isLoading ? null : _login,
                child: const Text('Login'),
              ),
              SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
