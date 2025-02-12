import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../models/book.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  bool isPlaying = false;
  final ScrollController _scrollController = ScrollController();
  List<String> sentences = [];
  List<String> translatedSentences = [];
  int currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _prepareSentences();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setVolume(0.5);
    await flutterTts.setPitch(0.8);

    flutterTts.setCompletionHandler(() {
      if (isPlaying) {
        _speakNext();
      }
    });
  }

  void _prepareSentences() {
    // Split content into sentences (basic implementation)
    sentences = widget.book.content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Translate all sentences
    _translateSentences();
  }

  Future<void> _translateSentences() async {
    for (String sentence in sentences) {
      try {
        var translation = await translator.translate(sentence, to: 'ko');
        translatedSentences.add(translation.text);
      } catch (e) {
        translatedSentences.add("Translation error: ${e.toString()}");
        print("Translation error: $e");
      }
    }
  }

  Future<void> _speakNext() async {
    if (!isPlaying || currentSentenceIndex >= sentences.length) {
      setState(() {
        isPlaying = false;
        currentSentenceIndex = 0;
      });
      return;
    }

    // Speak English
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(sentences[currentSentenceIndex]);

    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 500));

    // Speak Korean
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.speak(translatedSentences[currentSentenceIndex]);

    currentSentenceIndex++;
  }

  Future<void> _speak(String text) async {
    if (!isPlaying) {
      setState(() {
        isPlaying = true;
        currentSentenceIndex = 0;
      });
      _speakNext();
    } else {
      setState(() => isPlaying = false);
      await flutterTts.stop();
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            onPressed: () => _speak(widget.book.content),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'By ${widget.book.author}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              widget.book.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
