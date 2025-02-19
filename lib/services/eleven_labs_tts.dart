import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io'; // Import for GZipCodec
import 'dart:typed_data'; // Import Uint8List

class ElevenLabsTTS {
  final String apiKey = dotenv.env['ELEVEN_LABS_API_KEY']!;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> stop() async {
    print('Stopping Eleven Labs TTS');
    await _audioPlayer.stop();
    print('Audio stopped');
  }

  Future<void> speak(String text,
      {String? voiceId, bool whisper = false}) async {
    print("Attempting to speak: $text");
    try {
      final response = await http.post(
        Uri.parse(
            "https://api.elevenlabs.io/v1/text-to-speech/${voiceId ?? 'YOUR_VOICE_ID'}"),
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": apiKey,
        },
        body: jsonEncode({
          "text": text,
          "model_id": "eleven_monolingual_v1",
          "voice_settings": {
            "stability": whisper ? 0.1 : 0.5,
            "similarity_boost": whisper ? 0.9 : 0.7,
            "style": whisper ? 0.2 : 0.7,
          }
        }),
      );

      // Log the response status code
      print("Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Response headers: ${response.headers}");

        // Check if the response is audio data
        if (response.headers['content-type'] == 'audio/mpeg') {
          // Save the audio data to a temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/audio.mp3');
          await tempFile.writeAsBytes(response.bodyBytes);

          // Play the audio from the temporary file
          await _audioPlayer.play(DeviceFileSource(tempFile.path));
          print('Audio is playing from: ${tempFile.path}');
        } else {
          print("Unexpected content type: ${response.headers['content-type']}");
        }
      } else {
        print("TTS API Error: ${response.body}");
      }
    } catch (e) {
      print("Error during TTS API call: $e"); // Log any errors
    }
  }

  Future<Duration?> getCurrentPosition() async {
    Duration? position =
        await _audioPlayer.getCurrentPosition(); // Get current position
    print("Current position: $position");
    return position;
  }

  Future<void> seek(Duration position) async {
    print("Seeking to position: $position");
    await _audioPlayer.seek(position); // Seek to the specified position
  }

  Future<void> resume() async {
    print("Resuming audio playback");
    await _audioPlayer.resume(); // Resume playback
  }
}
