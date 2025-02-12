import 'package:my_book_reader/models/book.dart';

class BooksResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Book> books;

  BooksResponse({
    required this.count,
    this.next,
    this.previous,
    required this.books,
  });

  factory BooksResponse.fromJson(Map<String, dynamic> json) {
    return BooksResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      books: (json['results'] as List)
          .map((bookData) => Book.fromJson(bookData))
          .toList(),
    );
  }
}
