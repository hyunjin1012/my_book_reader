import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../models/book.dart';
import '../services/eleven_labs_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  BookReaderScreenState createState() => BookReaderScreenState();
}

class BookReaderScreenState extends State<BookReaderScreen> {
  final ElevenLabsTTS elevenLabsTts = ElevenLabsTTS(); // Use Eleven Labs TTS
  final translator = GoogleTranslator();
  bool isPlaying = false;
  final ScrollController _scrollController = ScrollController();
  List<String> sentences = [];
  List<String> translatedSentences = [];
  int currentSentenceIndex = 0;
  Duration? currentPosition; // Track the current position

  // Declare the selected voice ID variable
  String? selectedVoiceId;

  // Remove the hard-coded voices list
  List<Map<String, dynamic>> voices = [];

  @override
  void initState() {
    super.initState();
    _prepareSentences();
    _fetchVoices(); // Fetch voices on initialization
  }

  void _prepareSentences() {
    // Split content into sentences (basic implementation)
    sentences = widget.book.content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Split sentences into chunks of approximately 50 words
    List<String> wordChunks = [];
    String currentChunk = '';

    for (String sentence in sentences) {
      List<String> words = sentence.split(' ');
      for (String word in words) {
        if ((currentChunk.split(' ').length + 1) > 50) {
          wordChunks.add(currentChunk.trim());
          currentChunk = '';
        }
        currentChunk += '$word ';
      }
    }
    if (currentChunk.isNotEmpty) {
      wordChunks.add(currentChunk.trim());
    }

    sentences = wordChunks; // Update sentences to be the new word chunks

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

    // Get the current sentence
    String currentSentence = sentences[currentSentenceIndex];
    print(
        "Attempting to whisper: $currentSentence"); // Log the current sentence being whispered

    // Speak the entire sentence with whispering effect
    await elevenLabsTts.speak(currentSentence,
        voiceId: selectedVoiceId,
        whisper: true); // Assuming 'whisper' is a valid parameter
    await Future.delayed(const Duration(
        milliseconds: 500)); // Wait a bit before moving to the next sentence

    currentSentenceIndex++; // Move to the next sentence
    await _speakNext(); // Recursively call to speak the next sentence
  }

  Future<void> _speak(String text) async {
    print("Current state: isPlaying = $isPlaying");
    if (!isPlaying) {
      setState(() {
        isPlaying = true;
      });
      print("Starting to speak...");
      await _speakNext();
    } else {
      setState(() {
        isPlaying = false;
      });
      // Get the current position before stopping
      currentPosition =
          await elevenLabsTts.getCurrentPosition(); // Get current position
      print("Current position before stopping: $currentPosition");
      await elevenLabsTts.stop(); // Stop the audio
    }
  }

  Future<void> resumeAudio() async {
    print("Attempting to resume audio...");
    if (currentPosition != null) {
      print("Resuming audio from position: $currentPosition");
      await elevenLabsTts.seek(currentPosition!); // Seek to the last position
      await elevenLabsTts.resume(); // Resume playback
      setState(() {
        isPlaying = true; // Update the playing state
      });
    } else {
      print("No current position to resume from.");
      // New feedback for the user
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No audio position to resume from.")));

      // Start audio from the beginning
      currentSentenceIndex = 0; // Reset to the first sentence
      await _speak(widget.book.content); // Start speaking from the beginning
    }
  }

  @override
  void dispose() {
    elevenLabsTts.stop(); // Call the stop method
    super.dispose(); // Ensure the superclass dispose method is called
  }

  // New method to fetch voices from the API
  Future<void> _fetchVoices() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.elevenlabs.io/v1/voices'));
      if (response.statusCode == 200) {
        final List<dynamic> voiceData = json.decode(response.body)['voices'];
        setState(() {
          voices = voiceData
              .map((voice) => {
                    "id": voice['voice_id'] as String,
                    "name": voice['name'] as String,
                  })
              .toList();
        });
        print("Response body: ${response.body}");
      } else {
        throw Exception('Failed to load voices');
      }
    } catch (e) {
      print("Error fetching voices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Dropdown menu for voice selection
            DropdownButton<String>(
              hint: const Text("Select a voice"),
              value: selectedVoiceId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedVoiceId = newValue;
                });
              },
              items: voices.map<DropdownMenuItem<String>>((voice) {
                return DropdownMenuItem<String>(
                  value: voice["id"],
                  child: Text(voice["name"]!),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (isPlaying) {
                  _speak(widget.book.content); // Stop the audio
                } else {
                  resumeAudio(); // Resume the audio
                }
              },
              child: Text(isPlaying ? 'Stop' : 'Play'),
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
