import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'app_colors.dart';
import 'services/reading_api_service.dart';

class ReadingPractice extends StatefulWidget {
  final int exerciseId;
  const ReadingPractice({super.key, required this.exerciseId});

  @override
  State<ReadingPractice> createState() => _ReadingPracticeState();
}

class _ReadingPracticeState extends State<ReadingPractice> {
  // Instances partagées pour toute l'app : le moteur de reconnaissance vocale
  // et le TTS sont des singletons natifs côté iOS. En créer une nouvelle
  // instance à chaque écran laisse l'ancienne encore en cours de libération
  // (dispose() ne peut pas attendre les futures async), ce qui fait que le
  // 2e exercice s'initialise "en apparence" mais n'écoute jamais réellement.
  static final stt.SpeechToText _stt = stt.SpeechToText();
  static final FlutterTts _tts = FlutterTts();

  final _apiService = ReadingApiService();

  Map<String, dynamic>? _exercise;
  bool _isLoading = true;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isEvaluating = false;
  bool _speechAvailable = false;
  bool _isRecoveringSpeech = false;
  String _transcript = '';
  Map<String, dynamic>? _evaluationResult;
  String? _errorMessage;
  String? _lastSpeechError;
  Timer? _listenWatchdog;

  @override
  void initState() {
    super.initState();
    _loadExercise();
    _initSpeech();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _listenWatchdog?.cancel();
    _tts.stop();
    _stt.cancel();
    super.dispose();
  }

  void _cancelWatchdog() {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
  }

  Future<void> _initSpeech() async {
    // `initialize()` ne remet à jour onError/onStatus que lors du tout
    // premier appel sur l'instance (elle renvoie tôt si déjà initialisée).
    // Comme _stt est partagée entre tous les écrans, on réassigne ces
    // listeners nous-mêmes à chaque écran pour qu'ils pointent toujours
    // vers l'instance courante et pas un écran précédent déjà démonté.
    _stt.errorListener = _handleSpeechError;
    _stt.statusListener = _handleSpeechStatus;

    if (_stt.isAvailable) {
      if (mounted) setState(() => _speechAvailable = true);
      return;
    }

    final available = await _stt.initialize(
      onError: _stt.errorListener,
      onStatus: _stt.statusListener,
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint(
      'speech_to_text error: ${error.errorMsg} (permanent: ${error.permanent})',
    );
    _cancelWatchdog();
    if (!mounted) return;

    final isConnectionInterrupted =
        error.errorMsg == 'error_speech_recognizer_connection_interrupted';
    final isRetryable =
        isConnectionInterrupted || error.errorMsg == 'error_client';

    setState(() {
      _isListening = false;
      if (error.permanent && !isRetryable) _speechAvailable = false;
    });

    if (_transcript.isNotEmpty) {
      _evaluate();
      return;
    }

    if (isRetryable) {
      _recoverSpeechEngine();
    }

    final message = isConnectionInterrupted
        ? "La reconnaissance vocale s'est interrompue. Appuie encore sur le micro pour réessayer."
        : 'Speech error: ${error.errorMsg}';

    if (_lastSpeechError == message) return;
    _lastSpeechError = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    // iOS n'envoie pas toujours finalResult=true : on se fie aussi au statut.
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _cancelWatchdog();
        setState(() => _isListening = false);
        if (_transcript.isNotEmpty) _evaluate();
      }
    }
  }

  Future<void> _recoverSpeechEngine() async {
    if (_isRecoveringSpeech) return;
    _isRecoveringSpeech = true;
    try {
      await _stt.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final available = await _stt.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    } finally {
      _isRecoveringSpeech = false;
    }
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
    // Empêche les taps multiples de lancer plusieurs sessions d'écoute en parallèle.
    if (_isListening || _isEvaluating) return;

    _lastSpeechError = null;

    if (!_speechAvailable) {
      await _initSpeech();
      if (!mounted) return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone not available. Check permissions.'),
        ),
      );
      return;
    }

    // La lecture TTS et l'écoute STT se disputent la session audio iOS :
    // on coupe toujours le TTS avant de démarrer le micro.
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    }

    // _stt est partagée entre les écrans : on s'assure qu'aucune session
    // résiduelle d'un écran précédent (dispose() ne peut pas attendre son
    // cancel()) n'est encore active avant d'en démarrer une nouvelle.
    if (_stt.isListening) {
      await _stt.cancel();
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    setState(() {
      _isListening = true;
      _evaluationResult = null;
      _transcript = '';
    });

    try {
      await _stt.listen(
        onResult: (val) {
          if (!mounted) return;
          // Un résultat, même partiel, prouve que le moteur natif écoute bien.
          _cancelWatchdog();
          setState(() => _transcript = val.recognizedWords);
          if (val.finalResult) {
            setState(() => _isListening = false);
            _evaluate();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: _exercise?['language'] ?? 'en-US',
        ),
      );

      // Le moteur natif peut accepter la demande de listen() sans jamais
      // produire de résultat ni d'erreur (bug connu du simulateur iOS :
      // kAFAssistantErrorDomain Code=1101 après une 1ère utilisation).
      // On détecte ce silence et on redonne la main à l'utilisateur.
      _listenWatchdog = Timer(const Duration(seconds: 6), () {
        if (!mounted || !_isListening || _transcript.isNotEmpty) return;
        _stt.cancel();
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Le micro ne répond pas (limitation connue du simulateur iOS). "
              "Réessaie, ou teste sur un appareil réel.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Microphone error: $e')));
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    _cancelWatchdog();
    try {
      await _stt.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isListening = false);
    if (_transcript.isNotEmpty) _evaluate();
  }

  Future<void> _evaluate() async {
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

    // Le micro et le TTS se disputent la session audio iOS : on coupe
    // toujours l'écoute avant de démarrer la lecture.
    if (_isListening) {
      _cancelWatchdog();
      try {
        await _stt.stop();
      } catch (_) {}
      if (mounted) setState(() => _isListening = false);
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

    // Erreur de chargement
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
                            color: AppColors.primary.withOpacity(0.05),
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
                          // Spinner d'évaluation
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
                          if (_transcript.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '"$_transcript"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
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
