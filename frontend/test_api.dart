import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:libri_flow/features/home/data/models/book_model.dart';
import 'package:libri_flow/core/services/api_service.dart';

void main() async {
  try {
    ApiService.baseUrl = 'http://127.0.0.1:8000';
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/books/featured'),
    );
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final data = decoded['data'];
        if (data is List) {
          final books = data
              .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
              .toList();
          print('Successfully parsed ${books.length} featured books');
        } else {
          print('Data is not a list!');
        }
      } else {
        print('Decoded is not a map!');
      }
    } else {
      print('Body: ${response.body}');
    }

    final response2 = await http.get(Uri.parse('http://127.0.0.1:8000/books'));
    print('Status2: ${response2.statusCode}');
    if (response2.statusCode == 200) {
      final decoded = jsonDecode(response2.body);

      if (decoded is Map) {
        final data = decoded['data'];
        if (data is List) {
          final books = data
              .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
              .toList();
          print('Successfully parsed ${books.length} catalog books');
        }
      }
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
