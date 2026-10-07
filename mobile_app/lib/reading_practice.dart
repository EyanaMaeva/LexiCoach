import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'app_colors.dart';
import 'services/ai_conversation_api_service.dart';
import 'services/reading_api_service.dart';
import 'services/realtime_voice_service.dart';

class ReadingPractice extends StatefulWidget {
  final int exerciseId;
  const ReadingPractice({super.key, required this.exerciseId});

  @override
  State<ReadingPractice> createState() => _ReadingPracticeState();
}

class _ReadingPracticeState extends State<ReadingPractice> {
  static final FlutterTts _tts = FlutterTts();

  final _apiService = ReadingApiService();
  final _conversationApi = AiConversationApiService();
  final _transcriptController = TextEditingController();
  late final RealtimeVoiceService _realtimeVoice;

  Map<String, dynamic>? _exercise;
  bool _isLoading = true;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isEvaluating = false;
  String _transcript = '';
  Map<String, dynamic>? _evaluationResult;
  String? _errorMessage;
  int? _realtimeSessionId;

  @override
  void initState() {
    super.initState();
    _realtimeVoice = RealtimeVoiceService(
      onConnected: () {
        debugPrint('Reading realtime connected');
      },
      onDisconnected: () {
        debugPrint('Reading realtime disconnected');
      },
      onUserSpeechStarted: () {
        if (!mounted) return;
        setState(() => _isListening = true);
      },
      onUserSpeechStopped: () {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
      onUserTranscript: (transcript) {
        if (!mounted) return;
        _setTranscript(transcript);
        unawaited(_stopRealtimeCapture());
        _evaluate();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
      onLog: (message) {
        debugPrint('Reading realtime log: $message');
      },
    );
    _loadExercise();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    unawaited(_realtimeVoice.dispose());
    _transcriptController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    try {
      final data = await _apiService.getExerciseDetail(widget.exerciseId);
      if (!mounted) return;
      setState(() {
        _exercise = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isEvaluating) return;

    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    }

    setState(() {
      _isListening = true;
      _evaluationResult = null;
      _transcript = '';
    });
    _transcriptController.clear();

    try {
      final data = await _conversationApi.startRealtimeSession(
        topicName: 'Reading exercise',
      );
      final session = data['session'] as Map<String, dynamic>? ?? {};
      final realtime = data['realtime'] as Map<String, dynamic>? ?? {};
      final websocketUrl = realtime['url']?.toString();
      final clientSecret = realtime['client_secret']?.toString();
      final inputSampleRate = _intFrom(realtime['input_sample_rate'], 24000);

      if (websocketUrl == null || websocketUrl.trim().isEmpty) {
        throw Exception('Missing Realtime websocket URL.');
      }

      if (clientSecret == null || clientSecret.trim().isEmpty) {
        throw Exception('Missing Realtime client secret.');
      }

      _realtimeSessionId = _intFrom(session['id'], 0);

      await _realtimeVoice.start(
        websocketUrl: websocketUrl,
        headers: {'Authorization': 'Bearer $clientSecret'},
        sampleRate: inputSampleRate,
        createInitialResponse: false,
        createResponsesForTranscripts: false,
        sendSessionUpdate: false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _stopRealtimeCapture();
  }

  Future<void> _stopRealtimeCapture() async {
    final sessionId = _realtimeSessionId;
    _realtimeSessionId = null;

    await _realtimeVoice.stop();

    if (sessionId != null && sessionId > 0) {
      try {
        await _conversationApi.endRealtimeSession(sessionId);
      } catch (error) {
        debugPrint('Reading realtime end session failed: $error');
      }
    }

    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _evaluate() async {
    _transcript = _transcriptController.text.trim().isNotEmpty
        ? _transcriptController.text.trim()
        : _transcript.trim();

    if (_transcript.isEmpty || _isEvaluating) return;

    setState(() => _isEvaluating = true);
    try {
      final result = await _apiService.evaluateExercise(
        widget.exerciseId,
        _transcript,
      );
      if (!mounted) return;
      setState(() {
        _evaluationResult = result['result'];
        _isEvaluating = false;
      });
      _showFeedbackModal();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEvaluating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Evaluation error: $e')));
    }
  }

  Future<void> _speak() async {
    if (_exercise == null || _isSpeaking) return;

    // The microphone and TTS compete for the iOS audio session, so we
    // always stop listening before starting playback.
    if (_isListening) {
      await _stopRealtimeCapture();
    }

    setState(() => _isSpeaking = true);
    try {
      await _tts.setLanguage(_exercise!['language'] ?? 'en-US');
      await _tts.speak(_exercise!['text'] ?? '');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (!mounted) return;
    setState(() => _isSpeaking = false);
  }

  void _setTranscript(String transcript) {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) return;

    setState(() => _transcript = cleaned);

    if (_transcriptController.text != cleaned) {
      _transcriptController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
  }

  int _intFrom(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _showFeedbackModal() {
    if (_evaluationResult == null || !mounted) return;

    final feedback = _evaluationResult!['feedback'] as Map<String, dynamic>?;
    final score = _evaluationResult!['score'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              feedback?['title'] ?? 'Feedback',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Score: $score%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score as num),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              feedback?['message'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(num score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Loading initial
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Loading error
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadExercise();
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _exercise?['level']?.toString().toUpperCase() ??
                                'BEGINNER',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            _exercise?['title'] ?? 'Exercise',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // --- PROGRESS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: 0.3,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.logoBlue,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Read the sentence aloud',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- SENTENCE CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Text(
                        _exercise?['text'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- LISTEN BUTTON ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallActionButton(
                          icon: _isSpeaking
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          label: _isSpeaking ? 'Stop' : 'Listen',
                          onPressed: _isSpeaking ? _stopSpeaking : _speak,
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // --- MICROPHONE / STT SECTION ---
                    Center(
                      child: Column(
                        children: [
                          // Evaluation spinner
                          if (_isEvaluating)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(),
                            )
                          else
                            GestureDetector(
                              onTap: _isListening
                                  ? _stopListening
                                  : _startListening,
                              child: Lottie.asset(
                                'assets/lotties/AI logo Foriday (1).json',
                                height: 200,
                                animate: _isListening,
                              ),
                            ),
                          Text(
                            _isEvaluating
                                ? 'Evaluating...'
                                : _isListening
                                ? 'Listening... Tap to stop'
                                : 'Tap the AI to record',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _transcriptController,
                            minLines: 2,
                            maxLines: 4,
                            onChanged: (value) {
                              setState(() => _transcript = value.trim());
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Transcript appears here. You can correct it before evaluation.',
                              hintStyle: const TextStyle(
                                color: AppColors.textLight,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                  color: AppColors.textFieldBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                  color: AppColors.textFieldBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isEvaluating || _transcript.trim().isEmpty
                                  ? null
                                  : _evaluate,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Evaluate reading'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary
                                    .withValues(alpha: 0.4),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textFieldBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
