import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'main_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro - Focus Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF120421),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2A004A)),
      ),
      themeMode: ThemeMode.dark,
      home: const MainMenu(),
      routes: {
        '/timer': (context) => const MyHomePage(title: 'Pomodoro — Focus Pet'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum TimerMode { idle, study, rest }

class _MyHomePageState extends State<MyHomePage> {
  // Inputs controllers (now accept MM:SS format)
  final TextEditingController _studyCtrl = TextEditingController(text: '25:00');
  final TextEditingController _restCtrl = TextEditingController(text: '05:00');
  final TextEditingController _cyclesCtrl = TextEditingController(text: '4');

  Timer? _timer;
  TimerMode _mode = TimerMode.idle;
  bool _isRunning = false;

  int _totalSeconds = 0; // duration of current period
  int _remaining = 0; // remaining seconds in current period
  int _cycles = 1;
  int _currentCycle = 0;
  int _studyCompletedCount = 0; // contador de periodos de estudio completados
  final List<String> _encouragements = [
    'Muy bien hecho, sigue así',
    'Enhorabuena, lo has hecho genial',
    'Excelente trabajo, sigue esforzándote así y llegarás lejos',
  ];
  int _lastEncouragementIndex = -1;
  String? _encouragementMessage;
  bool _showEncouragement = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  // Focus nodes to track focus for input animation
  late FocusNode _studyFocus;
  late FocusNode _restFocus;
  late FocusNode _cyclesFocus;
  // Track whether a controller already reached max to avoid repeated clicks
  final Map<TextEditingController, bool> _reachedMax = {};

  @override
  void initState() {
    super.initState();
    _studyFocus = FocusNode();
    _restFocus = FocusNode();
    _cyclesFocus = FocusNode();

    _studyFocus.addListener(() => _onFieldFocusChange(_studyFocus, _studyCtrl));
    _restFocus.addListener(() => _onFieldFocusChange(_restFocus, _restCtrl));
    _cyclesFocus.addListener(
      () => _onFieldFocusChange(_cyclesFocus, _cyclesCtrl),
    );

    _reachedMax[_studyCtrl] = _studyCtrl.text.length >= 5;
    _reachedMax[_restCtrl] = _restCtrl.text.length >= 5;
    _reachedMax[_cyclesCtrl] = _cyclesCtrl.text.length >= 3;

    _studyCtrl.addListener(() => _onFieldTextChange(_studyCtrl, 5));
    _restCtrl.addListener(() => _onFieldTextChange(_restCtrl, 5));
    _cyclesCtrl.addListener(() => _onFieldTextChange(_cyclesCtrl, 3));
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    _studyCtrl.dispose();
    _restCtrl.dispose();
    _cyclesCtrl.dispose();
    _studyFocus.dispose();
    _restFocus.dispose();
    _cyclesFocus.dispose();
    super.dispose();
  }

  void _onFieldFocusChange(FocusNode node, TextEditingController ctrl) {
    if (!node.hasFocus) {
      _playClickSound();
    }
    setState(() {});
  }

  void _onFieldTextChange(TextEditingController ctrl, int maxLen) {
    final len = ctrl.text.length;
    if (len >= maxLen && !(_reachedMax[ctrl] ?? false)) {
      _reachedMax[ctrl] = true;
      _playClickSound();
    } else if (len < maxLen && (_reachedMax[ctrl] ?? false)) {
      _reachedMax[ctrl] = false;
    }
  }

  Future<void> _playClickSound() async {
    try {
      SystemSound.play(SystemSoundType.click);
      return;
    } catch (_) {}
    try {
      // fallback remote small click
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/button/sounds/button-16.mp3'),
      );
    } catch (_) {}
  }

  String _formatMMSS(int s) {
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // Parse input like "MM" or "MM:SS" or ":SS" into seconds.
  int _parseDurationInput(String input) {
    input = input.trim();
    if (input.isEmpty) return 0;
    if (input.contains(':')) {
      final parts = input.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return (m * 60) + s;
      }
      // if more segments, fallback to first two
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return (m * 60) + s;
    }
    // treat as minutes if only number provided
    final minutes = int.tryParse(input) ?? 0;
    return minutes * 60;
  }

  Future<void> _playEndSound() async {
    // On Windows desktop the audioplayers plugin can cause threading errors
    // (see logs). Use the system alert sound as a reliable fallback there.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      SystemSound.play(SystemSoundType.alert);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reproduciendo sonido de fin (sistema - Windows)'),
        ),
      );
      return;
    }

    // On other platforms (mobile, web, macOS, Linux), try asset -> remote -> system.
    try {
      // Preferred: play local asset if the user has added it under assets/
      await _audioPlayer.play(
        AssetSource('reverby-notification-sound-246407.mp3'),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reproduciendo sonido de fin (asset)')),
      );
      return;
    } catch (_) {
      // ignore and try remote
    }

    try {
      // Fallback remote short beep (requires network)
      const url = 'https://www.soundjay.com/button/sounds/beep-07.mp3';
      await _audioPlayer.play(UrlSource(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reproduciendo sonido de fin (remote)')),
      );
      return;
    } catch (_) {
      // final fallback to system sound
      SystemSound.play(SystemSoundType.alert);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reproduciendo sonido de fin (sistema)')),
      );
    }
  }

  Future<void> _playPopSound() async {
    try {
      await _audioPlayer.play(AssetSource('pop.mp3'));
    } catch (_) {
      // pop asset not available — user should add assets/pop.mp3 if desired
    }
  }

  Future<void> _playStudyEndSound() async {
    try {
      // Preferred: play local study-end asset if present
      await _audioPlayer.play(AssetSource('notification_sound.mp3'));
      return;
    } catch (_) {
      // fallback to generic end sound
    }
    await _playEndSound();
  }

  void _displayEncouragement() {
    // pick a random message but not equal to last
    final rnd = Random();
    int idx = rnd.nextInt(_encouragements.length);
    if (_lastEncouragementIndex >= 0 && _encouragements.length > 1) {
      while (idx == _lastEncouragementIndex) {
        idx = rnd.nextInt(_encouragements.length);
      }
    }
    _lastEncouragementIndex = idx;
    _encouragementMessage = _encouragements[idx];

    // play confetti and try pop sound
    try {
      _confettiController.play();
    } catch (_) {}
    _playPopSound();

    // feedback: vibrate on mobile, sound on desktop/fallback
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    } else {
      _playEndSound();
    }

    setState(() {
      _showEncouragement = true;
    });

    // hide after a short duration
    Future.delayed(const Duration(milliseconds: 2400), () {
      setState(() {
        _showEncouragement = false;
      });
    });
  }

  void _showNotification(String title, String body) {
    // In-app notification (SnackBar) and a dialog for clarity
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title — $body'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startTimerCycle() {
    final studySec = _parseDurationInput(_studyCtrl.text);
    final restSec = _parseDurationInput(_restCtrl.text);
    final cycles = int.tryParse(_cyclesCtrl.text) ?? 4;

    _cycles = cycles.clamp(1, 999);
    if (_currentCycle == 0) _currentCycle = 1;
    _mode = TimerMode.study;
    _totalSeconds = (studySec.clamp(1, 180 * 60));
    _remaining = _totalSeconds;
    _isRunning = true;

    _showNotification(
      'Comenzando',
      'Estudio: ${_formatMMSS(_totalSeconds)} — Ciclo $_currentCycle/$_cycles',
    );
    _startPeriodic(studySec, restSec);
    setState(() {});
  }

  void _startPeriodic(int studySec, int restSec) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() {
        _remaining--;
        if (_remaining < 0) {
          // period finished
          if (_mode == TimerMode.study) {
            // play study-end notification sound (prefer local asset)
            _playStudyEndSound();
            // finished a study period
            _studyCompletedCount++;
            // switch to rest
            _mode = TimerMode.rest;
            _totalSeconds = restSec.clamp(1, 60 * 60);
            _remaining = _totalSeconds;
            _showNotification(
              'Descanso',
              'Descanso: ${_formatMMSS(_totalSeconds)} — Ciclo $_currentCycle/$_cycles',
            );
          } else if (_mode == TimerMode.rest) {
            // finished a full cycle
            if (_currentCycle >= _cycles) {
              // finished all cycles
              _timer?.cancel();
              _timer = null;
              _mode = TimerMode.idle;
              _isRunning = false;
              _showNotification('¡Terminado!', 'Todos los ciclos completados.');
              // show encouragement with animation/vibration/sound
              _displayEncouragement();
              _currentCycle = 0;
              _totalSeconds = 0;
              _remaining = 0;
            } else {
              // next cycle study
              _currentCycle++;
              _mode = TimerMode.study;
              _totalSeconds = studySec.clamp(1, 180 * 60);
              _remaining = _totalSeconds;
              _playEndSound();
              _showNotification(
                'Estudio',
                'Estudio: ${_formatMMSS(_totalSeconds)} — Ciclo $_currentCycle/$_cycles',
              );
            }
          }
        }
      });
    });
  }

  void _onStartPressed() {
    if (_isRunning) return;
    // If paused (mode not idle and remaining > 0), resume
    if (_mode != TimerMode.idle && _remaining > 0) {
      _isRunning = true;
      setState(() {});
      return;
    }
    // Start fresh
    _currentCycle = 0;
    _startTimerCycle();
  }

  void _onPausePressed() {
    _isRunning = false;
    setState(() {});
  }

  void _onResetPressed() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _mode = TimerMode.idle;
    _currentCycle = 0;
    _totalSeconds = 0;
    _remaining = 0;
    setState(() {});
    _showNotification('Reiniciado', 'Temporizador reiniciado.');
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = _mode == TimerMode.study
        ? 'Estudio'
        : (_mode == TimerMode.rest ? 'Descanso' : 'Listo');

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), elevation: 2),
      body: Stack(
        children: [
          // Main content
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                // Big definition with tomato image (falls back to emoji if asset missing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // try to load local tomato image; if missing, show emoji
                    Image.asset(
                      'assets/tomato.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('🍅', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Pomodoro — alterna trabajo concentrado con breves descansos para mejorar la productividad.',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        'Estudio (MM:SS)',
                        _studyCtrl,
                        _studyFocus,
                        5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildNumberField(
                        'Descanso (MM:SS)',
                        _restCtrl,
                        _restFocus,
                        5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildNumberField(
                        'Repeticiones',
                        _cyclesCtrl,
                        _cyclesFocus,
                        3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRunning ? null : _onStartPressed,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isRunning ? _onPausePressed : null,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausa'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _onResetPressed,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                    const Spacer(),
                    Text(
                      modeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Timer display
                Center(
                  child: Column(
                    children: [
                      Text(
                        _formatMMSS(_remaining),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == TimerMode.idle
                            ? ''
                            : 'Ciclo $_currentCycle / $_cycles',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      // contador de estudios completados
                      Text(
                        'Ciclos de estudio terminados: $_studyCompletedCount',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Encouragement overlay
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showEncouragement,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (_showEncouragement && _encouragementMessage != null)
                      ? 1.0
                      : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: (_showEncouragement && _encouragementMessage != null)
                        ? 1.0
                        : 0.8,
                    curve: Curves.easeOutBack,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                          emissionFrequency: 0.05,
                          numberOfParticles: 30,
                          maxBlastForce: 40,
                          minBlastForce: 20,
                          colors: const [
                            Colors.greenAccent,
                            Colors.white,
                            Colors.amber,
                          ],
                        ),
                        (_encouragementMessage != null)
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _encouragementMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    int maxLen,
  ) {
    final scale = focusNode.hasFocus ? 1.08 : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale, scale),
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: controller == _cyclesCtrl
                ? [FilteringTextInputFormatter.digitsOnly]
                : [FilteringTextInputFormatter.allow(RegExp(r'[\d:]'))],
            maxLength: maxLen,
            onEditingComplete: _playClickSound,
            onSubmitted: (_) => _playClickSound(),
            decoration: InputDecoration(
              hintText: controller == _cyclesCtrl ? null : 'MM:SS',
              counterText: '',
              border: const OutlineInputBorder(),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF1B0133),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
