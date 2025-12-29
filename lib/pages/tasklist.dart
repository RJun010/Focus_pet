import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

enum Priority { alta, media, baja }

class Task {
  final String title;
  final Priority priority;
  final Color color;
  Task(this.title, this.priority, this.color);
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});
  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with TickerProviderStateMixin {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  int completedCount = 0;

  String? _congratsMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTaskModal(String text) {
    Priority selectedPriority = Priority.media;
    Color selectedColor = Colors.blueAccent;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Selecciona prioridad y color",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: Priority.values.map((p) {
                        return GestureDetector(
                          onTap: () =>
                              setStateModal(() => selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPriority == p
                                  ? (p == Priority.alta
                                        ? Colors.redAccent
                                        : p == Priority.media
                                        ? Colors.orangeAccent
                                        : Colors.green)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: selectedPriority == p
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ...Colors.primaries.take(8).map((c) {
                          final isSelected = selectedColor == c;
                          return GestureDetector(
                            onTap: () => setStateModal(() => selectedColor = c),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white24,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _tasks.add(
                            Task(text, selectedPriority, selectedColor),
                          );
                          _tasks.sort(
                            (a, b) =>
                                a.priority.index.compareTo(b.priority.index),
                          );
                          _controller.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Agregar tarea"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('TaskList', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Inbox",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_congratsMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedOpacity(
                        opacity: _congratsMessage != null ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _congratsMessage!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Añadir tarea…",
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF1C2233),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          backgroundColor: const Color(0xFF4F7DFF),
                          onPressed: () async {
                            if (_controller.text.isNotEmpty) {
                              final p = AudioPlayer();
                              try {
                                await p.play(AssetSource('pop.mp3'));
                                Future.delayed(
                                  const Duration(milliseconds: 800),
                                  () async {
                                    try {
                                      await p.dispose();
                                    } catch (_) {}
                                  },
                                );
                              } catch (_) {
                                try {
                                  await p.dispose();
                                } catch (_) {}
                              }
                              _showTaskModal(_controller.text);
                            }
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return _BreakableTaskWithCongratsAndClick(
                          task: task,
                          onCompleted: (message) {
                            setState(() {
                              completedCount++;
                              _congratsMessage = message;
                            });
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                _tasks.removeAt(index);
                                _congratsMessage = null;
                              });
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakableTaskWithCongratsAndClick extends StatefulWidget {
  final Task task;
  final void Function(String message) onCompleted;
  const _BreakableTaskWithCongratsAndClick({
    required this.task,
    required this.onCompleted,
  });

  @override
  State<_BreakableTaskWithCongratsAndClick> createState() =>
      _BreakableTaskWithCongratsAndClickState();
}

class _BreakableTaskWithCongratsAndClickState
    extends State<_BreakableTaskWithCongratsAndClick>
    with TickerProviderStateMixin {
  late AnimationController _popController;
  late AnimationController _fragController;
  bool completed = false;
  final List<_Fragment> _fragments = List.generate(12, (_) => _Fragment());

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  Future<void> _markCompleted() async {
    if (completed) return;
    completed = true;
    setState(() {});
    final p = AudioPlayer();
    try {
      await p.play(AssetSource('pop.mp3'));
      Future.delayed(const Duration(milliseconds: 800), () async {
        try {
          await p.dispose();
        } catch (_) {}
      });
    } catch (_) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _popController.forward().then((_) {
      _fragController.forward().then((_) {
        widget.onCompleted(
          '🎉 ¡Felicidades por completar "${widget.task.title}"!',
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _popController,
          builder: (_, __) {
            final scale = 1 + 0.2 * sin(_popController.value * pi);
            return AnimatedBuilder(
              animation: _fragController,
              builder: (_, __) {
                final opacity = (1.0 - _fragController.value).clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: widget.task.color,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                onPressed: _markCompleted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _Fragment {}
