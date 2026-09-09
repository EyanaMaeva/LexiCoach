import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
  final _apiService = ReadingApiService();
  final _stt = stt.SpeechToText();
  final _tts = FlutterTts();

  Map<String, dynamic>? _exercise;
  bool _isLoading = true;
  bool _isListening = false;
  String _transcript = "";
  Map<String, dynamic>? _evaluationResult;

  @override
  void initState() {
    super.initState();
    _loadExercise();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _stt.initialize();
  }

  Future<void> _loadExercise() async {
    try {
      final data = await _apiService.getExerciseDetail(widget.exerciseId);
      setState(() {
        _exercise = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      Navigator.pop(context);
    }
  }

  void _startListening() async {
    bool available = await _stt.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _evaluationResult = null;
        _transcript = "";
      });
      _stt.listen(
        onResult: (val) => setState(() {
          _transcript = val.recognizedWords;
          if (val.finalResult) {
            _isListening = false;
            _evaluate();
          }
        }),
        localeId: _exercise?['language'] ?? 'en-US',
      );
    }
  }

  void _stopListening() async {
    await _stt.stop();
    setState(() => _isListening = false);
  }

  Future<void> _evaluate() async {
    if (_transcript.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.evaluateExercise(widget.exerciseId, _transcript);
      setState(() {
        _evaluationResult = result['result'];
        _isLoading = false;
      });
      _showFeedbackModal();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evaluation Error: $e")));
    }
  }

  Future<void> _speak() async {
    if (_exercise == null) return;
    await _tts.setLanguage(_exercise!['language'] ?? 'en-US');
    await _tts.speak(_exercise!['text']);
  }

  void _showFeedbackModal() {
    if (_evaluationResult == null) return;

    final feedback = _evaluationResult!['feedback'];
    final score = _evaluationResult!['score'];

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
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Text(
              feedback['title'] ?? 'Feedback',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              "Your Score: $score%",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getScoreColor(score)),
            ),
            const SizedBox(height: 24),
            Text(
              feedback['message'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    if (_isLoading && _exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                          Text(_exercise?['level']?.toString().toUpperCase() ?? "BEGINNER",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.5)),
                          Text(
                            _exercise?['title'] ?? "Exercise",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                value: 0.3, // Example progress
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.logoBlue),
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
                    const Text("Read the sentence aloud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 32),

                    // --- SENTENCE CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
                      ),
                      child: Text(
                        _exercise?['text'] ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, height: 1.4, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- ACTION BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallActionButton(
                          icon: Icons.volume_up_rounded,
                          label: "Listen",
                          onPressed: _speak,
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // --- MICROPHONE / STT SECTION ---
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isListening ? _stopListening : _startListening,
                            child: Lottie.asset(
                              "assets/lotties/AI logo Foriday (1).json",
                              height: 200,
                              animate: _isListening,
                            ),
                          ),
                          Text(
                            _isListening ? "Listening..." : "Tap the AI to record",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLight),
                          ),
                          if (_transcript.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '"$_transcript"',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.primary),
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

  Widget _buildSmallActionButton({required IconData icon, required String label, required VoidCallback onPressed}) {
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}
