import 'dart:convert';
import 'package:http/http.dart' as http;

class DisneyService {
  static const String baseUrl = 'https://api.disneyapi.dev/';

  static Future<List<dynamic>> fetchCharacters({int page = 1}) async {
    final response = await http.get(Uri.parse('${baseUrl}character?page=$page&pageSize=50'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']; // List karakter
    } else {
      throw Exception('Failed to load characters');
    }
  }

  static Future<Map<String, dynamic>> fetchCharacterDetail(int id) async {
    final response = await http.get(Uri.parse('${baseUrl}character/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load character detail');
    }
  }
}
