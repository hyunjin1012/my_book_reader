import 'package:flutter/material.dart';
import '../services/gutenberg_service.dart';
import 'book_reader_screen.dart';
import 'book_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final GutenbergService _gutenbergService = GutenbergService();

  void _fetchAndOpenBook(String bookId) async {
    try {
      final book = await _gutenbergService.fetchBook(bookId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReaderScreen(book: book),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading book: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gutenberg Reader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter Book ID',
                hintText: 'e.g., 1661 for "The Adventures of Sherlock Holmes"',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _fetchAndOpenBook(_controller.text);
                }
              },
              child: const Text('Fetch Book'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookListScreen(),
                  ),
                );
              },
              child: const Text('Go to Book List'),
            ),
          ],
        ),
      ),
    );
  }
}
