import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  late List<bool> _completedDays;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // 🎊 Initialize confetti controller
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Initialize checkboxes based on current streak
    _completedDays = List.generate(
      widget.habit.goalDays,
      (index) => widget.habit.streak > 0 && index < widget.habit.streak,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _toggleDay(int index) {
    setState(() {
      // Toggle that specific day's completion
      _completedDays[index] = !_completedDays[index];

      // Count how many boxes are checked
      int checkedCount = _completedDays.where((e) => e).length;

      // Update the habit model
      widget.habit.streak = checkedCount;

      // Mark habit as completed only if all are checked
      bool isFullyComplete = _completedDays.every((e) => e);
      widget.habit.completedToday = isFullyComplete;

      // 🎉 Show Hurray + Confetti only when *all* boxes just got completed
      if (isFullyComplete && checkedCount == widget.habit.goalDays) {
        _showFullScreenConfetti(); // 🎊 play confetti
        _showHurrayOverlay(context); // optional text overlay
      }
    });

    // Notify parent widget to update top "Done:" count
    widget.onToggle();
  }

  void _showHurrayOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Center(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                'Hurray!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      entry.remove();
    });
  }

  void _showFullScreenConfetti() {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              alignment: Alignment.topCenter,
              children: List.generate(5, (i) {
                // Create 5 emitters across the top width
                return Align(
                  alignment: Alignment(
                      -1.0 + i * 0.5, -1.0), // left to right across top
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2, // straight down
                    blastDirectionality: BlastDirectionality.directional,
                    shouldLoop: false,
                    emissionFrequency: 0.04,
                    numberOfParticles: 10,
                    gravity: 0.2,
                    maxBlastForce: 6,
                    minBlastForce: 3,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.orange,
                      Colors.purple,
                      Colors.pink,
                      Colors.yellow,
                      Colors.teal,
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _confettiController.play();

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _completedDays.every((e) => e);
    final border = allDone ? Colors.green.shade300 : Colors.grey.shade200;
    final bg = allDone ? Colors.green.shade50 : Colors.white;
    final strike = allDone ? TextDecoration.lineThrough : TextDecoration.none;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // ✅ row of check buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.habit.goalDays, (index) {
                  final isChecked = _completedDays[index];
                  return GestureDetector(
                    onTap: () => _toggleDay(index),
                    child: AnimatedContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      duration: const Duration(milliseconds: 250),
                      height: 26,
                      width: 26,
                      decoration: BoxDecoration(
                        color: isChecked ? Colors.green : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isChecked
                            ? [
                                BoxShadow(
                                  color: Colors.green.shade200,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        isChecked ? Icons.check : Icons.radio_button_unchecked,
                        color: isChecked ? Colors.white : Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(width: 12),

              // Habit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: strike,
                      ),
                    ),
                    Row(
                      children: [
                        Text(widget.habit.category),
                        if (widget.habit.goalDays > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_completedDays.where((e) => e).length}/${widget.habit.goalDays}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Edit / Delete buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: widget.onEdit,
                    icon: Icon(Icons.edit_outlined, color: Colors.grey[700]),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
