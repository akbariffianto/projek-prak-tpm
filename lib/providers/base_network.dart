import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class BaseNetwork {
  static const String _baseUrl = 'https://restaurant-api.dicoding.dev/';
  static final _logger = Logger();

  //dinamic digunakan karena kita tidak tahu tipe datanya biar dia flexible
  static Future<List<Map<String, dynamic>>> getAll(String path) async {
    //Meminta data dari API
    final uri = Uri.parse("$_baseUrl/$path");
    _logger.i("GET ALL : $uri");

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      _logger.i("Response : ${response.statusCode}");
      _logger.t("Body : ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        _logger.e("Error : ${response.statusCode}");
        throw Exception("Server Error : ${response.statusCode}");
      }
    } on TimeoutException {
      _logger.e("Request timeout : $uri");
      throw Exception("Request timeout");
    } catch (e) {
      _logger.e("Error fetching data from $uri : $e");
      throw Exception("Error fetching data : $e");
    }
  }
}