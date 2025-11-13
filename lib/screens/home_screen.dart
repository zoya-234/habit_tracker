import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/habit.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({this.onToggleTheme, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String storageKey = 'habits_v1';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  // ✅ Load habits safely (no animation)
  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? [];

    final loaded = raw.map((s) => Habit.fromJson(s)).toList();

    setState(() {
      _habits.clear();
      _habits.addAll(loaded);
      _loading = false;
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _habits.map((h) => h.toJson()).toList();
    await prefs.setStringList(storageKey, raw);
  }

  // ✅ Safe add habit (prevents index errors)
  void _addHabit(Habit habit) {
    setState(() {
      _habits.insert(0, habit);
    });

    if (_listKey.currentState != null && _listKey.currentState!.mounted) {
      _listKey.currentState!
          .insertItem(0, duration: const Duration(milliseconds: 400));
    }

    _saveHabits();
  }

  // ✅ Safe delete habit
  void _deleteHabit(String id) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index < 0 || index >= _habits.length) return;

    final removed = _habits.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: HabitCard(
            habit: removed,
            onToggle: () {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
    );

    Future.delayed(const Duration(milliseconds: 350), _saveHabits);
  }

  void _editHabit(Map<String, dynamic> map) {
    final edited = Habit.fromMap(map);
    final i = _habits.indexWhere((h) => h.id == edited.id);
    if (i >= 0) {
      setState(() {
        _habits[i] = edited;
      });
      _saveHabits();
    }
  }

  void _toggleCompleted(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i < 0) return;
    setState(() {}); // simple rebuild
    await _saveHabits();
  }

  void _openAddScreen() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result == null) return;

    if (result is Map<String, dynamic>) {
      final returnedId = result['id'] as String;
      final exists = _habits.any((h) => h.id == returnedId);

      if (exists) {
        final edited = Habit.fromMap(result);
        final idx = _habits.indexWhere((h) => h.id == returnedId);
        if (idx >= 0) {
          setState(() => _habits[idx] = edited);
        }
        await _saveHabits();
      } else {
        final newHabit = Habit.fromMap(result);
        _addHabit(newHabit);
      }
    } else if (result is Habit) {
      _addHabit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 700;
    final total = _habits.length;
    final done = _habits.where((h) => h.streak >= h.goalDays).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'HabiTrack',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.tealAccent : Colors.green.shade900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: isDark ? Colors.tealAccent : Colors.green.shade900,
            ),
            tooltip: 'Toggle Dark Mode',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                for (var h in _habits) h.completedToday = false;
              });
              _saveHabits();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset today\'s completions')),
              );
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Reset Today',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Stack(
              children: [
                Container(
                  height: isWide ? 200 : 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1C2541), const Color(0xFF0B132B)]
                          : [Colors.green.shade700, Colors.green.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 36 : 20,
                      vertical: 18,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                'Your Daily Habits',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Small reps, big results — track a habit each day.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _SummaryChip(label: 'Total', value: '$total'),
                                  const SizedBox(width: 8),
                                  _SummaryChip(label: 'Done', value: '$done'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: isWide ? 96 : 72,
                          height: isWide ? 96 : 72,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_florist,
                                    color: Colors.white,
                                    size: isWide ? 36 : 28),
                                const SizedBox(height: 4),
                                const Text('Grow',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
//comment to push the code again

            const SizedBox(height: 14),

            // Main Habit List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 36 : 16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _habits.isEmpty
                        ? _EmptyState(onAddTap: _openAddScreen)
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: _habits.length,
                            itemBuilder: (context, index, animation) {
                              if (index >= _habits.length) {
                                return const SizedBox.shrink(); // safety check
                              }

                              final habit = _habits[index];
                              return SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.vertical,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: HabitCard(
                                    habit: habit,
                                    onToggle: () => _toggleCompleted(habit.id),
                                    onDelete: () => _deleteHabit(habit.id),
                                    onEdit: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/add',
                                        arguments: habit.toMap(),
                                      );
                                      if (result != null &&
                                          result is Map<String, dynamic>) {
                                        _editHabit(result);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded,
              size: mq.size.width > 600 ? 96 : 72,
              color: Colors.green.shade300),
          const SizedBox(height: 14),
          const Text('No habits yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text('Add a daily habit and watch your streak grow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onAddTap,
            child: const Text('Add your first habit',
                style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}
