import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceState { idle, listening, processing, speaking, error }

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceState _state = VoiceState.idle;
  String _recognizedWords = '';
  String _errorMessage = '';
  bool _isSpeechAvailable = false;
  bool _isTtsAvailable = true;

  VoiceState get state => _state;
  String get recognizedWords => _recognizedWords;
  String get errorMessage => _errorMessage;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isProcessing => _state == VoiceState.processing;
  bool get isSpeechAvailable => _isSpeechAvailable;

  SpeechService() {
    _initTts();
  }

  Future<void> initSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == VoiceState.listening) {
              _setState(VoiceState.idle);
            }
          }
        },
        onError: (val) {
          _errorMessage = val.errorMsg;
          _setState(VoiceState.error);
        },
      );
    } catch (e) {
      _isSpeechAvailable = false;
      _errorMessage = 'Speech recognition not available on this platform: $e';
    }
    notifyListeners();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      _tts.setStartHandler(() {
        _setState(VoiceState.speaking);
      });

      _tts.setCompletionHandler(() {
        if (_state == VoiceState.speaking) {
          _setState(VoiceState.idle);
        }
      });

      _tts.setCancelHandler(() {
        if (_state == VoiceState.speaking) {
          _setState(VoiceState.idle);
        }
      });

      _tts.setErrorHandler((msg) {
        _errorMessage = 'TTS Error: $msg';
        _setState(VoiceState.idle);
      });
    } catch (_) {
      _isTtsAvailable = false;
    }
  }

  void _setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    if (processing) {
      _setState(VoiceState.processing);
    } else if (_state == VoiceState.processing) {
      _setState(VoiceState.idle);
    }
  }

  Future<void> startListening({required Function(String text) onResult}) async {
    // Cancel any ongoing speech first
    await stopSpeaking();

    if (!_isSpeechAvailable) {
      await initSpeech();
    }

    if (!_isSpeechAvailable) {
      _errorMessage = 'Microphone or speech recognition unavailable. Please use text input.';
      _setState(VoiceState.error);
      return;
    }

    _recognizedWords = '';
    _errorMessage = '';
    _setState(VoiceState.listening);

    try {
      await _speech.listen(
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            _setState(VoiceState.idle);
            onResult(_recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      _errorMessage = 'Error starting microphone: $e';
      _setState(VoiceState.error);
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _setState(VoiceState.idle);
  }

  Future<void> speak(String text) async {
    if (!_isTtsAvailable || text.trim().isEmpty) return;

    // Prevent overlapping speech: stop previous first!
    await stopSpeaking();

    try {
      _setState(VoiceState.speaking);
      await _tts.speak(text);
    } catch (e) {
      _setState(VoiceState.idle);
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (_state == VoiceState.speaking) {
      _setState(VoiceState.idle);
    }
  }

  void clearError() {
    _errorMessage = '';
    _setState(VoiceState.idle);
  }
}
