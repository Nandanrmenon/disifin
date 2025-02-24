import 'dart:convert';

import 'package:http/http.dart' as http;

class JellyfinApi {
  final String baseUrl;
  final String apiKey;

  JellyfinApi({required this.baseUrl, required this.apiKey});

  Future<List<dynamic>> getMusic() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Items?IncludeItemTypes=Audio&api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['Items'];
    } else {
      throw Exception('Failed to load music');
    }
  }
}
