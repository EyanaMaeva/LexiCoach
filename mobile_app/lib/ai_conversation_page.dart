import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'app_colors.dart';
import 'services/ai_conversation_api_service.dart';
import 'services/auth_module.dart';
import 'services/pcm_audio_player.dart';
import 'services/realtime_voice_service.dart';

class AiConversationPage extends StatefulWidget {
  const AiConversationPage({super.key});

  @override
  State<AiConversationPage> createState() => _AiConversationPageState();
}

class _AiConversationPageState extends State<AiConversationPage> {
  final _authApi = AuthApiService();
  final _conversationApi = AiConversationApiService();
  late final RealtimeVoiceService _realtimeVoice;
  late final PcmAudioPlayer _pcmPlayer;

  Timer? _timer;
  bool _isLoading = true;
  bool _isWorking = false;
  bool _isSessionActive = false;
  bool _isRealtimeReady = false;
  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _isAwaitingReply = false;
  bool _autoStartRequested = false;
  String? _errorMessage;
  String? _liveTranscript;
  String _lastAssistantTranscript = '';
  Map<String, dynamic>? _assessment;
  int? _sessionId;
  int _sessionLimitSeconds = 180;
  int _dailySessionLimit = 3;
  int _remainingSeconds = 180;
  final List<_ConversationMessage> _messages = [
    const _ConversationMessage(
      text: 'Start a session, tap the microphone, then speak naturally.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pcmPlayer = PcmAudioPlayer();
    _pcmPlayer.onPlaybackIdle = () {
      debugPrint('AI conversation OpenAI playback idle');
      _realtimeVoice.notifyNativePlaybackIdle();
    };
    _realtimeVoice = RealtimeVoiceService(
      onConnected: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI Realtime connected');
        setState(() => _isRealtimeReady = true);
      },
      onDisconnected: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI Realtime disconnected');
        setState(() {
          _isRealtimeReady = false;
          _isRecording = false;
          _isAwaitingReply = false;
          _isSpeaking = false;
        });
      },
      onUserSpeechStarted: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI user speech started');
        setState(() {
          _isRecording = true;
          _liveTranscript = 'Listening...';
        });
      },
      onUserSpeechStopped: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI user speech stopped');
        setState(() {
          _isRecording = false;
          _isAwaitingReply = true;
          _liveTranscript = 'Thinking...';
        });
      },
      onUserTranscript: (transcript) {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI USER transcript="$transcript"');
        setState(() {
          _liveTranscript = transcript;
          _messages.add(_ConversationMessage(text: transcript, isUser: true));
        });
      },
      onAssistantAudioStarted: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI assistant audio started');
        setState(() {
          _isAwaitingReply = true;
          _isSpeaking = true;
          _liveTranscript = 'Speaking...';
        });
      },
      onAssistantAudioChunk: (chunk) {
        unawaited(_pcmPlayer.playChunk(chunk));
      },
      onAssistantAudioStreamDone: () {
        debugPrint('AI conversation OpenAI assistant audio stream done');
        unawaited(_pcmPlayer.markStreamEnd());
      },
      onAssistantTranscript: (reply) {
        if (!mounted) return;
        if (reply == _lastAssistantTranscript) return;
        _lastAssistantTranscript = reply;
        debugPrint('AI conversation OpenAI ASSISTANT transcript="$reply"');
        setState(() {
          _liveTranscript = reply;
          _messages.add(_ConversationMessage(text: reply, isUser: false));
        });
      },
      onAssistantAudioStopped: () {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI assistant audio stopped');
        setState(() {
          _isSpeaking = false;
          _isAwaitingReply = false;
          _liveTranscript = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint('AI conversation OpenAI Realtime error=$error');
        setState(() {
          _isRecording = false;
          _isAwaitingReply = false;
          _isRealtimeReady = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
      onLog: (message) {
        debugPrint('AI conversation OpenAI log: $message');
      },
    );
    _loadLimits();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_realtimeVoice.dispose());
    unawaited(_pcmPlayer.dispose());
    super.dispose();
  }

  Future<void> _loadLimits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authApi.me();
      final user = response['data']?['user'] as Map<String, dynamic>?;
      final limits = user?['conversation_limits'] as Map<String, dynamic>?;

      final sessionLimit = _asInt(limits?['session_limit_seconds'], 180);
      final dailyLimit = _asInt(limits?['daily_session_limit'], 3);

      if (!mounted) return;

      setState(() {
        _sessionLimitSeconds = sessionLimit;
        _dailySessionLimit = dailyLimit;
        _remainingSeconds = sessionLimit;
        _isLoading = false;
      });

      if (!_autoStartRequested && dailyLimit > 0) {
        _autoStartRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_startVoiceConversation());
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _startSession() async {
    if (_isWorking) return false;

    if (_dailySessionLimit == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI conversation is disabled for today.')),
      );
      return false;
    }

    _timer?.cancel();

    setState(() => _isWorking = true);

    try {
      final data = await _conversationApi.startRealtimeSession();
      final session = data['session'] as Map<String, dynamic>?;
      final quota = data['quota'] as Map<String, dynamic>?;
      final realtime = data['realtime'] as Map<String, dynamic>;
      final sessionLimit = _asInt(
        session?['session_limit_seconds'],
        _sessionLimitSeconds,
      );
      final sessionId = _asInt(session?['id'], 0);

      if (!mounted) return false;

      setState(() {
        _sessionId = sessionId;
        _sessionLimitSeconds = sessionLimit;
        _remainingSeconds = _asInt(session?['remaining_seconds'], sessionLimit);
        _dailySessionLimit = _asInt(
          quota?['daily_session_limit'],
          _dailySessionLimit,
        );
        _isSessionActive = true;
        _assessment = null;
        _isWorking = false;
        _isRealtimeReady = false;
        _liveTranscript = null;
        _messages
          ..clear()
          ..add(
            const _ConversationMessage(
              text: 'Connecting to your voice coach...',
              isUser: false,
            ),
          );
      });

      _startLocalTimer();
      await _connectOpenAiRealtime(realtime);
      return true;
    } catch (error) {
      if (!mounted) return false;

      setState(() => _isWorking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return false;
    }
  }

  Future<void> _connectOpenAiRealtime(Map<String, dynamic> realtime) async {
    final websocketUrl = realtime['url']?.toString();
    final clientSecret = realtime['client_secret']?.toString();
    final inputSampleRate = _asInt(realtime['input_sample_rate'], 24000);
    final outputSampleRate = _asInt(realtime['output_sample_rate'], 24000);

    if (websocketUrl == null || websocketUrl.trim().isEmpty) {
      throw Exception('Missing OpenAI Realtime websocket URL.');
    }

    if (clientSecret == null || clientSecret.trim().isEmpty) {
      throw Exception('Missing OpenAI Realtime client secret.');
    }

    await _pcmPlayer.configure(sampleRate: outputSampleRate, channels: 1);
    debugPrint(
      'AI conversation pcm player configured sampleRate=$outputSampleRate',
    );

    await _realtimeVoice.start(
      websocketUrl: websocketUrl,
      headers: {'Authorization': 'Bearer $clientSecret'},
      sampleRate: inputSampleRate,
      createInitialResponse: true,
      sendSessionUpdate: false,
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (!_isSessionActive) {
      await _startVoiceConversation();
    } else {
      await _stopSession();
    }
  }

  Future<void> _startVoiceConversation() async {
    if (_isWorking) return;

    final started = await _startSession();
    if (!started || !mounted) return;

    final ready = await _waitForRealtimeReady();
    if (!ready || !mounted || !_isSessionActive) return;
    setState(() {
      _messages
        ..clear()
        ..add(
          const _ConversationMessage(
            text: 'The coach is starting the conversation.',
            isUser: false,
          ),
        );
    });
  }

  Future<void> _stopSession() async {
    if (_isWorking) return;

    await _endBackendSession(resetTimer: true);
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isSessionActive = false;
        });
        _endBackendSession(resetTimer: false);
        _showTimeEndedMessage();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  Future<void> _endBackendSession({required bool resetTimer}) async {
    final sessionId = _sessionId;
    _timer?.cancel();
    await _stopVoiceRecordingIfNeeded();
    await _realtimeVoice.stop();
    await _pcmPlayer.stop();

    if (sessionId == null || sessionId == 0) {
      setState(() {
        _isRealtimeReady = false;
        _isSessionActive = false;
        _isRecording = false;
        _isSpeaking = false;
        _liveTranscript = null;
        _remainingSeconds = resetTimer ? _sessionLimitSeconds : 0;
      });
      return;
    }

    setState(() => _isWorking = true);

    try {
      final data = resetTimer
          ? await _conversationApi.endRealtimeSession(sessionId)
          : await _conversationApi.expireSession(sessionId);
      final quota = data['quota'] as Map<String, dynamic>?;
      final assessment = await _safeAssessSession(sessionId);

      if (!mounted) return;

      setState(() {
        _sessionId = null;
        _isRealtimeReady = false;
        _isRecording = false;
        _isSpeaking = false;
        _dailySessionLimit = _asInt(
          quota?['daily_session_limit'],
          _dailySessionLimit,
        );
        _isSessionActive = false;
        _remainingSeconds = resetTimer ? _sessionLimitSeconds : 0;
        _assessment = assessment;
        _liveTranscript = null;
        _isWorking = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isWorking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _stopVoiceRecordingIfNeeded() async {
    if (!_isRecording) return;

    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  Future<Map<String, dynamic>?> _safeAssessSession(int sessionId) async {
    try {
      final data = await _conversationApi.assessSession(sessionId);
      return data['assessment'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  void _showTimeEndedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session ended. Time limit reached.')),
    );
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$remainingSeconds';
  }

  Future<bool> _waitForRealtimeReady() async {
    for (var i = 0; i < 20; i++) {
      if (_isRealtimeReady) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OpenAI Realtime is not ready yet.')),
    );
    return false;
  }

  double get _progress {
    if (_sessionLimitSeconds <= 0) return 0;
    return _remainingSeconds / _sessionLimitSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final voiceStatus = _isRecording
        ? 'Listening...'
        : _isAwaitingReply
        ? 'Thinking...'
        : _isSpeaking
        ? 'Speaking...'
        : _isSessionActive
        ? 'Conversation active'
        : 'Connecting...';

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
        title: const Text(
          'AI Conversation',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadLimits)
          : _VoiceConversationView(
              remainingTime: _formatDuration(_remainingSeconds),
              progress: _progress,
              status: voiceStatus,
              isSessionActive: _isSessionActive,
              isWorking: _isWorking,
              isReady: _isRealtimeReady,
              isRecording: _isRecording,
              isSpeaking: _isSpeaking,
              isAwaitingReply: _isAwaitingReply,
              liveTranscript: _liveTranscript,
              messages: _messages,
              assessment: _assessment,
              onStop: _stopSession,
              onToggleRecording: _toggleVoiceRecording,
            ),
    );
  }
}

class _VoiceConversationView extends StatelessWidget {
  const _VoiceConversationView({
    required this.remainingTime,
    required this.progress,
    required this.status,
    required this.isSessionActive,
    required this.isWorking,
    required this.isReady,
    required this.isRecording,
    required this.isSpeaking,
    required this.isAwaitingReply,
    required this.liveTranscript,
    required this.messages,
    required this.assessment,
    required this.onStop,
    required this.onToggleRecording,
  });

  final String remainingTime;
  final double progress;
  final String status;
  final bool isSessionActive;
  final bool isWorking;
  final bool isReady;
  final bool isRecording;
  final bool isSpeaking;
  final bool isAwaitingReply;
  final String? liveTranscript;
  final List<_ConversationMessage> messages;
  final Map<String, dynamic>? assessment;
  final VoidCallback onStop;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    final visibleMessages = messages.length > 4
        ? messages.sublist(messages.length - 4)
        : messages;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            Row(
              children: [
                _SmallStatusChip(
                  icon: Icons.schedule_rounded,
                  label: remainingTime,
                ),
                const Spacer(),
                if (isSessionActive)
                  _SoftIconButton(
                    icon: Icons.close_rounded,
                    color: AppColors.logoOrange,
                    onPressed: isWorking ? null : onStop,
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 230,
              width: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 4,
                      backgroundColor: AppColors.textFieldBorder.withValues(
                        alpha: 0.55,
                      ),
                      color: isSessionActive
                          ? AppColors.primary
                          : AppColors.logoTeal,
                    ),
                  ),
                  Container(
                    height: 205,
                    width: 205,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 34,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Lottie.asset(
                        'assets/lotties/AI logo Foriday (1).json',
                        repeat:
                            isSessionActive ||
                            isRecording ||
                            isSpeaking ||
                            isAwaitingReply,
                        animate:
                            isSessionActive ||
                            isRecording ||
                            isSpeaking ||
                            isAwaitingReply,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                liveTranscript?.isNotEmpty == true
                    ? liveTranscript!
                    : isSessionActive
                    ? 'Speak naturally after the coach finishes.'
                    : 'The coach starts automatically.',
                key: ValueKey(liveTranscript ?? isSessionActive),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            if (assessment != null) ...[
              _CompactAssessment(assessment: assessment!),
              const SizedBox(height: 14),
            ] else if (visibleMessages.isNotEmpty) ...[
              _VoiceTranscriptPreview(messages: visibleMessages),
              const SizedBox(height: 18),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MainVoiceButton(
                  isRecording: isRecording,
                  isSessionActive: isSessionActive,
                  isWorking: isWorking,
                  isEnabled: !isSessionActive || isReady,
                  onPressed: onToggleRecording,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  const _SmallStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 44,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.55),
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.textFieldBorder),
          ),
        ),
        icon: Icon(icon, color: color),
      ),
    );
  }
}

class _MainVoiceButton extends StatelessWidget {
  const _MainVoiceButton({
    required this.isRecording,
    required this.isSessionActive,
    required this.isWorking,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isRecording;
  final bool isSessionActive;
  final bool isWorking;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isSessionActive ? AppColors.logoOrange : AppColors.primary;

    return GestureDetector(
      onTap: (isEnabled || isRecording) && !isWorking ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 82,
        width: 82,
        decoration: BoxDecoration(
          color: isEnabled || isRecording || isWorking
              ? color
              : AppColors.textFieldBorder,
          shape: BoxShape.circle,
          boxShadow: [
            if (isEnabled || isRecording || isWorking)
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Icon(
          isWorking
              ? Icons.more_horiz_rounded
              : isSessionActive || isRecording
              ? Icons.stop_rounded
              : Icons.graphic_eq_rounded,
          color: isEnabled || isRecording || isWorking
              ? Colors.white
              : AppColors.textLight,
          size: 38,
        ),
      ),
    );
  }
}

class _VoiceTranscriptPreview extends StatelessWidget {
  const _VoiceTranscriptPreview({required this.messages});

  final List<_ConversationMessage> messages;

  @override
  Widget build(BuildContext context) {
    final last = messages.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: (last.isUser ? AppColors.primary : AppColors.logoTeal)
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              last.isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
              color: last.isUser ? AppColors.primary : AppColors.logoTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              last.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAssessment extends StatelessWidget {
  const _CompactAssessment({required this.assessment});

  final Map<String, dynamic> assessment;

  @override
  Widget build(BuildContext context) {
    final score = _AssessmentCard._asInt(assessment['score']);
    final feedback = assessment['feedback'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.logoTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: AppColors.logoTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedback?['message']?.toString() ?? 'Session complete.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationMessage {
  const _ConversationMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment});

  final Map<String, dynamic> assessment;

  @override
  Widget build(BuildContext context) {
    final score = _asInt(assessment['score']);
    final feedback = assessment['feedback'] as Map<String, dynamic>?;
    final title = feedback?['title']?.toString() ?? 'Session feedback';
    final message =
        feedback?['message']?.toString() ?? 'Keep practicing with short turns.';
    final nextStep =
        assessment['recommended_next_step']?.toString() ??
        'Practice one short answer again.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: AppColors.logoTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.logoTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$score%',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScoreChip(
                label: 'Fluency',
                value: _asInt(assessment['fluency']),
              ),
              _ScoreChip(
                label: 'Words',
                value: _asInt(assessment['vocabulary']),
              ),
              _ScoreChip(
                label: 'Grammar',
                value: _asInt(assessment['grammar']),
              ),
              _ScoreChip(
                label: 'Confidence',
                value: _asInt(assessment['confidence']),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Next: $nextStep',
            style: const TextStyle(
              color: AppColors.primary,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value%',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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
              Icons.cloud_off_rounded,
              color: AppColors.logoOrange,
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load conversation limits.',
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
