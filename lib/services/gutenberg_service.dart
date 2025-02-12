import 'package:http/http.dart' as http;
import 'package:my_book_reader/models/booksResponse.dart';
import '../models/book.dart';
import 'dart:convert';

class GutenbergService {
  static const String baseUrl = 'https://www.gutenberg.org';
  static const String apiUrl = 'https://gutendex.com';

  Future<Book> fetchBook(String bookId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/files/$bookId/$bookId-0.txt'));

    if (response.statusCode == 200) {
      final content = response.body;

      // Basic parsing to get title and author (you might want to improve this)
      final lines = content.split('\n');
      String title = '';
      String author = '';

      for (var line in lines) {
        if (line.contains('Title:')) {
          title = line.replaceAll('Title:', '').trim();
        }
        if (line.contains('Author:')) {
          author = line.replaceAll('Author:', '').trim();
        }
      }

      return Book(
        id: bookId,
        title: title,
        author: author,
        content: content,
      );
    } else {
      throw Exception('Failed to load book');
    }
  }

  Future<BooksResponse> fetchBooks({int page = 1, int limit = 32}) async {
    final response =
        await http.get(Uri.parse('$apiUrl/books?page=$page&limit=$limit'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return BooksResponse.fromJson(data);
    } else {
      throw Exception('Failed to load books');
    }
  }
}
