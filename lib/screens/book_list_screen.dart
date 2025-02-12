import 'package:flutter/material.dart';
import 'package:my_book_reader/models/booksResponse.dart';
import 'book_reader_screen.dart';
import 'package:my_book_reader/services/gutenberg_service.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  int _currentPage = 1; // Track the current page
  BooksResponse? _booksResponse; // Store the fetched books response
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchBooks(); // Fetch books when the screen is initialized
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    try {
      final response = await GutenbergService().fetchBooks(page: _currentPage);
      setState(() {
        // Filter out non-English book titles
        _booksResponse = BooksResponse(
          count: response.count,
          books:
              response.books.where((book) => _isEnglish(book.title)).toList(),
          next: response.next,
          previous: response.previous,
        ); // Update the state with the filtered response
      });

      // Log the count of books
      print('Total number of books: ${_booksResponse!.count}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching books: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
  }

  bool _isEnglish(String title) {
    // Simple check for English characters (you can enhance this logic)
    return RegExp(r'^[\x00-\x7F]+$').hasMatch(title);
  }

  Future<void> _fetchBookById(int id) async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    try {
      final bookDetails = await GutenbergService()
          .fetchBook(id.toString()); // Fetch book details by ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReaderScreen(
              book: bookDetails), // Pass the fetched book details
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching book: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
  }

  void _nextPage() {
    if (_booksResponse?.next != null) {
      setState(() {
        _currentPage++;
      });
      _fetchBooks(); // Fetch the next page
    }
  }

  void _previousPage() {
    if (_booksResponse?.previous != null) {
      setState(() {
        _currentPage--;
      });
      _fetchBooks(); // Fetch the previous page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book List'),
      ),
      body: _isLoading // Show loading indicator if loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _booksResponse?.books.length ?? 0,
                    itemBuilder: (context, index) {
                      final book = _booksResponse!.books[index];
                      return ListTile(
                        title: Text(book.title),
                        onTap: () {
                          _fetchBookById(
                              int.parse(book.id)); // Fetch book by ID
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      child: const Text('Previous'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _booksResponse?.next != null ? _nextPage : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
