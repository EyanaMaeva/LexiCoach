import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app_colors.dart';
import 'const.dart';
import 'payment_webview_page.dart';
import 'services/smart_abstract_api_service.dart';

const _logTag = '[Payment]';

class SmartAbstractPractice extends StatefulWidget {
  const SmartAbstractPractice({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  State<SmartAbstractPractice> createState() => _SmartAbstractPracticeState();
}

class _SmartAbstractPracticeState extends State<SmartAbstractPractice> {
  final _apiService = SmartAbstractApiService();
  final _documentController = TextEditingController();
  final _tts = FlutterTts();

  Map<String, dynamic>? _exercise;
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  bool _isEvaluating = false;
  bool _isPreparingListen = false;
  bool _isSpeaking = false;
  String? _errorMessage;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadExercise();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _documentController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    try {
      final exercise = await _apiService.getExerciseDetail(widget.exerciseId);
      if (!mounted) return;

      setState(() {
        _exercise = exercise;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _evaluate() async {
    if (_isEvaluating) return;

    final documentText = _documentController.text.trim();

    if (documentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the document first.')),
      );
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final data = await _apiService.evaluateExercise(
        id: widget.exerciseId,
        documentText: documentText,
      );
      if (!mounted) return;

      setState(() {
        _result = data['result'];
        _isEvaluating = false;
      });
      _showResultSheet();
    } catch (error) {
      if (!mounted) return;

      setState(() => _isEvaluating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _showResultSheet() {
    if (_result == null || !mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textFieldBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _ResultCard(result: _result!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reads the document aloud with local TTS.
  /// Smart Abstract summaries remain free.
  Future<void> _listenToDocument() async {
    if (_isSpeaking) {
      debugPrint('$_logTag _listenToDocument: stop requested by user');
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    if (_isPreparingListen) return;

    final documentText = _documentController.text.trim();
    if (documentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the document first.')),
      );
      return;
    }

    setState(() => _isPreparingListen = true);
    debugPrint(
      '$_logTag _listenToDocument: starting paid-listen flow for exercise=${widget.exerciseId}',
    );

    try {
      final paid = await _ensurePayment();
      debugPrint(
        '$_logTag _listenToDocument: _ensurePayment resolved with paid=$paid',
      );

      if (!paid) {
        debugPrint(
          '$_logTag _listenToDocument: aborting, payment was not confirmed',
        );
        if (mounted) setState(() => _isPreparingListen = false);
        return;
      }

      await _apiService.consumeListenCredit(widget.exerciseId);
      debugPrint(
        '$_logTag _listenToDocument: credit consumed, starting TTS playback',
      );
      if (!mounted) return;

      setState(() {
        _isPreparingListen = false;
        _isSpeaking = true;
      });

      await _tts.setLanguage(_exercise?['language'] ?? 'en-US');
      await _tts.speak(documentText);
    } catch (error) {
      debugPrint(
        '$_logTag _listenToDocument: error for exercise=${widget.exerciseId}: $error',
      );
      if (!mounted) return;

      setState(() {
        _isPreparingListen = false;
        _isSpeaking = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  /// Creates a Mercy Pay checkout session, opens it in an in-app WebView,
  /// then waits for webhook confirmation.
  Future<bool> _ensurePayment() async {
    debugPrint(
      '$_logTag _ensurePayment: creating checkout session for exercise=${widget.exerciseId}',
    );

    final Map<String, dynamic> checkout;
    try {
      checkout = await _apiService.createCheckout(widget.exerciseId);
    } catch (error) {
      debugPrint('$_logTag _ensurePayment: createCheckout failed: $error');
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $error')));
      return false;
    }

    final payment = checkout['payment'] as Map<String, dynamic>;
    final checkoutUrl = checkout['checkout_url']?.toString() ?? '';
    final paymentId = payment['id'] as int;

    if (checkoutUrl.isEmpty) {
      debugPrint(
        '$_logTag _ensurePayment: empty checkout_url in response: $checkout',
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the payment page.')),
      );
      return false;
    }

    if (!mounted) return false;

    debugPrint(
      '$_logTag _ensurePayment: opening webview payment_id=$paymentId url=$checkoutUrl',
    );

    // The WebView closes when it detects a success/cancel redirect, but that
    // does not prove payment client-side. We still wait for webhook
    // confirmation via _waitForPaymentCompletion.
    final webviewResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(
          checkoutUrl: checkoutUrl,
          successUrlPrefix: '$webBaseUrl/payments/smart-abstract/success',
          cancelUrlPrefix: '$webBaseUrl/payments/smart-abstract/cancel',
        ),
      ),
    );

    debugPrint(
      '$_logTag _ensurePayment: webview closed for payment_id=$paymentId result=$webviewResult',
    );

    if (!mounted) return false;
    return _waitForPaymentCompletion(
      paymentId,
      maxWait: webviewResult == false
          ? const Duration(seconds: 8)
          : const Duration(minutes: 10),
    );
  }

  Future<bool> _waitForPaymentCompletion(
    int paymentId, {
    Duration maxWait = const Duration(minutes: 10),
  }) async {
    final completer = Completer<bool>();
    Timer? timer;
    var elapsedSeconds = 0;
    const pollInterval = Duration(seconds: 3);

    void finish(bool result, String reason) {
      debugPrint(
        '$_logTag _waitForPaymentCompletion: payment_id=$paymentId finished '
        'result=$result reason="$reason" after ${elapsedSeconds}s',
      );
      timer?.cancel();
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
      if (!completer.isCompleted) completer.complete(result);
    }

    if (!mounted) return false;

    debugPrint(
      '$_logTag _waitForPaymentCompletion: polling started payment_id=$paymentId '
      'interval=${pollInterval.inSeconds}s maxWait=${maxWait.inSeconds}s',
    );

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 20),
              const Expanded(
                child: Text('Waiting for payment confirmation (100 FCFA)...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => finish(false, 'cancelled by user'),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );

    timer = Timer.periodic(pollInterval, (_) async {
      elapsedSeconds += pollInterval.inSeconds;

      try {
        final status = await _apiService.getPaymentStatus(paymentId);
        final value = status['status']?.toString();
        debugPrint(
          '$_logTag _waitForPaymentCompletion: poll payment_id=$paymentId '
          'elapsed=${elapsedSeconds}s status=$value',
        );

        if (value == 'completed') {
          finish(true, 'status=completed');
        } else if (value == 'failed') {
          finish(false, 'status=failed');
        } else if (elapsedSeconds >= maxWait.inSeconds) {
          finish(false, 'timeout waiting for completion');
        }
      } catch (error) {
        debugPrint(
          '$_logTag _waitForPaymentCompletion: poll error payment_id=$paymentId '
          'elapsed=${elapsedSeconds}s error=$error',
        );
        if (elapsedSeconds >= maxWait.inSeconds) {
          finish(false, 'timeout after poll errors');
        }
      }
    });

    return completer.future;
  }

  Future<void> _pickDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final extension = file.extension?.toLowerCase();
      final content = extension == 'pdf'
          ? await _extractPdfText(bytes, file.name)
          : utf8.decode(bytes, allowMalformed: true);

      if (content.trim().isEmpty) {
        throw Exception('The selected file is empty.');
      }

      if (!mounted) return;

      setState(() {
        _selectedFileName = file.name;
        _documentController.text = content.trim();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String> _extractPdfText(List<int> bytes, String fileName) async {
    await pdfrxFlutterInitialize();

    final document = await PdfDocument.openData(
      Uint8List.fromList(bytes),
      sourceName: fileName,
    );

    try {
      final buffer = StringBuffer();

      for (final page in document.pages) {
        final pageText = await page.loadText();
        final text = pageText?.fullText.trim();

        if (text != null && text.isNotEmpty) {
          buffer
            ..writeln(text)
            ..writeln();
        }
      }

      final extracted = buffer.toString().trim();

      if (extracted.isEmpty) {
        throw Exception(
          'No selectable text was found in this PDF. Try a text PDF, not a scanned image.',
        );
      }

      return extracted;
    } finally {
      await document.dispose();
    }
  }

  int _wordCount() {
    final summary = _documentController.text.trim();

    if (summary.isEmpty) return 0;

    return summary.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorState(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _loadExercise();
          },
        ),
      );
    }

    final minWords = _exercise?['min_words'] ?? 20;
    final maxWords = _exercise?['max_words'] ?? 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _exercise?['title'] ?? 'Smart Abstract',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _SourceTextCard(
            exercise: _exercise!,
            selectedFileName: _selectedFileName,
            onPickFile: _pickDocument,
            onUseSample: () {
              _documentController.text = (_exercise?['source_text'] ?? '')
                  .toString();
              setState(() => _selectedFileName = null);
            },
          ),
          const SizedBox(height: 18),
          _SummaryInput(
            controller: _documentController,
            wordCount: _wordCount(),
            minWords: minWords,
            maxWords: maxWords,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isEvaluating ? null : _evaluate,
                    icon: _isEvaluating
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _isEvaluating ? 'Summarizing...' : 'Generate Summary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.65,
                      ),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isPreparingListen ? null : _listenToDocument,
                    icon: _isPreparingListen
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.logoBlue,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isSpeaking
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _isPreparingListen
                          ? 'Paying...'
                          : _isSpeaking
                          ? 'Stop'
                          : 'Listen (100 FCFA)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.logoBlue,
                      side: const BorderSide(color: AppColors.logoBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceTextCard extends StatelessWidget {
  const _SourceTextCard({
    required this.exercise,
    required this.selectedFileName,
    required this.onPickFile,
    required this.onUseSample,
  });

  final Map<String, dynamic> exercise;
  final String? selectedFileName;
  final VoidCallback onPickFile;
  final VoidCallback onUseSample;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoTeal.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.logoTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: AppColors.logoTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise['level']?.toString().toUpperCase() ?? 'BEGINNER',
                  style: const TextStyle(
                    color: AppColors.logoTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Upload a PDF or paste a document. LexiCoach will turn it into a simple summary.',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          if ((exercise['instructions'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              exercise['instructions'],
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    selectedFileName == null
                        ? 'Choose document'
                        : selectedFileName!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.textFieldBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: onUseSample,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Sample'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.logoTeal,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Accepted files: .pdf, .txt and .md',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryInput extends StatelessWidget {
  const _SummaryInput({
    required this.controller,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int wordCount;
  final int minWords;
  final int maxWords;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final characterCount = controller.text.length;

    return TextField(
      controller: controller,
      minLines: 7,
      maxLines: 11,
      onChanged: (_) => onChanged(),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Paste the document text here...',
        labelText: 'Document to summarize',
        hintStyle: const TextStyle(color: AppColors.textLight),
        helperText:
            '$wordCount words - $characterCount/100000 characters - summary target $minWords-$maxWords words',
        helperStyle: TextStyle(
          color: characterCount <= 100000
              ? AppColors.logoTeal
              : AppColors.textLight,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final feedback = result['feedback'] as Map<String, dynamic>?;
    final keyPoints = result['strengths'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoBlue.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.logoBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.summarize_rounded,
                  color: AppColors.logoBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  feedback?['title'] ?? 'Summary ready',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            title: 'Summary',
            icon: Icons.auto_fix_high_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            result['improved_summary'] ?? '',
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (keyPoints.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Key points',
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 8),
            ...keyPoints.map((point) => _BulletText(text: point.toString())),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.logoOrange,
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load this exercise.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
