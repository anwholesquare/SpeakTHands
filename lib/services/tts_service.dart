import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace_model.dart';

enum TTSProvider {
  flutter,
  openai,
}

enum OpenAIVoice {
  alloy('alloy', 'Alloy - Natural and balanced'),
  echo('echo', 'Echo - Clear and expressive'),
  fable('fable', 'Fable - Warm and engaging'),
  onyx('onyx', 'Onyx - Deep and authoritative'),
  nova('nova', 'Nova - Bright and energetic'),
  shimmer('shimmer', 'Shimmer - Soft and pleasant');

  const OpenAIVoice(this.id, this.description);
  final String id;
  final String description;
}

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  
  String? _openaiApiKey;
  TTSProvider _currentProvider = TTSProvider.flutter;
  OpenAIVoice _openaiVoice = OpenAIVoice.alloy;
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;

  // Getters
  TTSProvider get currentProvider => _currentProvider;
  OpenAIVoice get openaiVoice => _openaiVoice;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  bool get hasOpenAIKey => _openaiApiKey != null && _openaiApiKey!.isNotEmpty;

  Future<void> initialize() async {
    await _loadSettings();
    await _initializeFlutterTts();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _openaiApiKey = prefs.getString('openai_api_key');
    _currentProvider = TTSProvider.values[prefs.getInt('tts_provider') ?? 0];
    _openaiVoice = OpenAIVoice.values[prefs.getInt('openai_voice') ?? 0];
    _speechRate = prefs.getDouble('speech_rate') ?? 0.5;
    _volume = prefs.getDouble('volume') ?? 1.0;
    _pitch = prefs.getDouble('pitch') ?? 1.0;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', _openaiApiKey ?? '');
    await prefs.setInt('tts_provider', _currentProvider.index);
    await prefs.setInt('openai_voice', _openaiVoice.index);
    await prefs.setDouble('speech_rate', _speechRate);
    await prefs.setDouble('volume', _volume);
    await prefs.setDouble('pitch', _pitch);
  }

  Future<void> _initializeFlutterTts() async {
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    
    // Set up platform-specific settings
    if (Platform.isAndroid) {
      await _flutterTts.setEngine("com.google.android.tts");
    }
  }

  // Settings management
  Future<void> setOpenAIApiKey(String apiKey) async {
    _openaiApiKey = apiKey;
    await _saveSettings();
  }

  Future<void> setTTSProvider(TTSProvider provider) async {
    _currentProvider = provider;
    await _saveSettings();
  }

  Future<void> setOpenAIVoice(OpenAIVoice voice) async {
    _openaiVoice = voice;
    await _saveSettings();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
    await _saveSettings();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _flutterTts.setVolume(volume);
    await _saveSettings();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
    await _saveSettings();
  }

  // Main TTS function
  Future<bool> speak(String text, {String? languageCode}) async {
    try {
      if (_currentProvider == TTSProvider.openai && hasOpenAIKey) {
        return await _speakWithOpenAI(text, languageCode: languageCode);
      } else {
        return await _speakWithFlutterTTS(text, languageCode: languageCode);
      }
    } catch (e) {
      print('TTS Error: $e');
      // Fallback to Flutter TTS if OpenAI fails
      if (_currentProvider == TTSProvider.openai) {
        return await _speakWithFlutterTTS(text, languageCode: languageCode);
      }
      return false;
    }
  }

  Future<bool> _speakWithFlutterTTS(String text, {String? languageCode}) async {
    try {
      if (languageCode != null) {
        await _flutterTts.setLanguage(languageCode);
      }
      
      final result = await _flutterTts.speak(text);
      return result == 1; // 1 indicates success
    } catch (e) {
      print('Flutter TTS Error: $e');
      return false;
    }
  }

  Future<bool> _speakWithOpenAI(String text, {String? languageCode}) async {
    try {
      if (_openaiApiKey == null || _openaiApiKey!.isEmpty) {
        throw Exception('OpenAI API key not set');
      }

      // Generate audio using OpenAI TTS API
      final response = await _dio.post(
        'https://api.openai.com/v1/audio/speech',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openaiApiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
        data: {
          'model': 'tts-1',
          'input': text,
          'voice': _openaiVoice.id,
          'response_format': 'mp3',
          'speed': _speechRate * 2, // OpenAI speed range is 0.25-4.0
        },
      );

      if (response.statusCode == 200) {
        // Save audio to temporary file and play
        final audioData = Uint8List.fromList(response.data);
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(audioData);

        // Play the audio
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        
        // Clean up the temporary file after a delay
        Future.delayed(const Duration(seconds: 30), () {
          if (audioFile.existsSync()) {
            audioFile.deleteSync();
          }
        });

        return true;
      }
      return false;
    } catch (e) {
      print('OpenAI TTS Error: $e');
      return false;
    }
  }

  // Generate and save audio for gesture
  Future<String?> generateAndSaveAudio(
    String text, 
    String gestureId,
    {String? languageCode}
  ) async {
    try {
      if (_currentProvider == TTSProvider.openai && hasOpenAIKey) {
        return await _generateOpenAIAudio(text, gestureId, languageCode: languageCode);
      } else {
        // For Flutter TTS, we don't pre-generate audio files
        // We'll speak directly when needed
        return null;
      }
    } catch (e) {
      print('Generate Audio Error: $e');
      return null;
    }
  }

  Future<String?> _generateOpenAIAudio(
    String text, 
    String gestureId,
    {String? languageCode}
  ) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/audio/speech',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openaiApiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
        data: {
          'model': 'tts-1-hd', // Higher quality for saved audio
          'input': text,
          'voice': _openaiVoice.id,
          'response_format': 'mp3',
          'speed': _speechRate * 2,
        },
      );

      if (response.statusCode == 200) {
        // Save to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${appDir.path}/audio');
        if (!audioDir.existsSync()) {
          audioDir.createSync(recursive: true);
        }

        final audioFile = File('${audioDir.path}/$gestureId.mp3');
        await audioFile.writeAsBytes(response.data);
        return audioFile.path;
      }
      return null;
    } catch (e) {
      print('Generate OpenAI Audio Error: $e');
      return null;
    }
  }

  // Play saved audio file
  Future<bool> playSavedAudio(String audioPath) async {
    try {
      if (File(audioPath).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(audioPath));
        return true;
      }
      return false;
    } catch (e) {
      print('Play Saved Audio Error: $e');
      return false;
    }
  }

  // Stop current speech/audio
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
    } catch (e) {
      print('Stop TTS Error: $e');
    }
  }

  // Get available languages for Flutter TTS
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print('Get Languages Error: $e');
      return [];
    }
  }

  // Get available voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      print('Get Voices Error: $e');
      return [];
    }
  }

  // Test TTS with sample text
  Future<bool> testTTS({String? languageCode}) async {
    final testTexts = {
      'en': 'Hello, this is a test of the text-to-speech system.',
      'es': 'Hola, esta es una prueba del sistema de texto a voz.',
      'fr': 'Bonjour, ceci est un test du système de synthèse vocale.',
      'de': 'Hallo, das ist ein Test des Text-zu-Sprache-Systems.',
      'it': 'Ciao, questo è un test del sistema di sintesi vocale.',
      'pt': 'Olá, este é um teste do sistema de conversão de texto em fala.',
      'zh': '你好，这是文本转语音系统的测试。',
      'ja': 'こんにちは、これはテキスト読み上げシステムのテストです。',
      'ko': '안녕하세요, 이것은 텍스트 음성 변환 시스템의 테스트입니다.',
      'ar': 'مرحبا، هذا اختبار لنظام تحويل النص إلى كلام.',
    };

    final testText = testTexts[languageCode ?? 'en'] ?? testTexts['en']!;
    return await speak(testText, languageCode: languageCode);
  }

  // Get language code for supported language
  String getLanguageCodeForSupportedLanguage(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.english:
        return 'en-US';
      case SupportedLanguage.spanish:
        return 'es-ES';
      case SupportedLanguage.french:
        return 'fr-FR';
      case SupportedLanguage.german:
        return 'de-DE';
      case SupportedLanguage.italian:
        return 'it-IT';
      case SupportedLanguage.portuguese:
        return 'pt-PT';
      case SupportedLanguage.chinese:
        return 'zh-CN';
      case SupportedLanguage.japanese:
        return 'ja-JP';
      case SupportedLanguage.korean:
        return 'ko-KR';
      case SupportedLanguage.arabic:
        return 'ar-SA';
    }
  }

  // Cleanup resources
  void dispose() {
    _audioPlayer.dispose();
  }
} 