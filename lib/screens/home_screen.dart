import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/widgets/habit_card.dart';
// import 'package:animated_background/animated_background.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final String storageKey = 'habits_v1';
  List<Habit> _habits = [];
  bool _loading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? [];
    setState(() {
      _habits = raw.map((s) => Habit.fromJson(s)).toList();
      _loading = false;
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _habits.map((h) => h.toJson()).toList();
    await prefs.setStringList(storageKey, raw);
  }

  void _addHabit(Habit habit) {
    setState(() {
      _habits.insert(0, habit);
      _listKey.currentState
          ?.insertItem(0, duration: Duration(milliseconds: 420));
    });
    _saveHabits();
  }

  void _toggleCompleted(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i < 0) return;
    setState(() {}); // Rebuilds UI and recalculates Done count
    await _saveHabits();
  }

  void _deleteHabit(String id) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index < 0) return;
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
      duration: Duration(milliseconds: 350),
    );
    _saveHabits();
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

  void _openAddScreen() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result == null) return;

    // Add / Edit both come back as Map<String, dynamic> (habit.toMap())
    if (result is Map<String, dynamic>) {
      final returnedId = result['id'] as String;
      final exists = _habits.any((h) => h.id == returnedId);

      if (exists) {
        // edit case: replace existing habit
        final edited = Habit.fromMap(result);
        final idx = _habits.indexWhere((h) => h.id == returnedId);
        if (idx >= 0) {
          setState(() => _habits[idx] = edited);
        }
        await _saveHabits();
      } else {
        // new habit: insert at top and animate
        final newHabit = Habit.fromMap(result);
        setState(() {
          _habits.insert(0, newHabit);
          // animate insert if AnimatedList is present
          _listKey.currentState
              ?.insertItem(0, duration: Duration(milliseconds: 420));
        });
        await _saveHabits();
      }
    } else if (result is Habit) {
      // fallback if Add screen returned a Habit object directly
      setState(() {
        _habits.insert(0, result);
        _listKey.currentState
            ?.insertItem(0, duration: Duration(milliseconds: 420));
      });
      await _saveHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 700;
    final total = _habits.length;
    final done = _habits.where((h) => h.streak >= h.goalDays).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Habit Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                for (var h in _habits) h.completedToday = false;
              });
              _saveHabits();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reset today\'s completions')));
            },
            icon: Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Reset Today',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // header (Stack)
            Stack(
              children: [
                Container(
                  height: isWide ? 200 : 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400]),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6))
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 36 : 20, vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text('Your Daily Habits',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: Colors.white)),
                              SizedBox(height: 6),
                              Text(
                                  'Small reps, big results — track a habit each day.',
                                  style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 10),
                              // summary chip row inside header
                              Row(
                                children: [
                                  _SummaryChip(label: 'Total', value: '$total'),
                                  SizedBox(width: 8),
                                  _SummaryChip(label: 'Done', value: '$done'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // fancy circular badge
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
                                SizedBox(height: 4),
                                Text('Grow',
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

            SizedBox(height: 14),

            // main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 36 : 16),
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _habits.isEmpty
                        ? _EmptyState(onAddTap: _openAddScreen)
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: _habits.length,
                            itemBuilder: (context, index, animation) {
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
                                      // open add screen in edit mode
                                      final result = await Navigator.pushNamed(
                                          context, '/add',
                                          arguments: habit.toMap());
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(width: 8),
          Text(value,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          SizedBox(height: 14),
          Text('No habits yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text('Add a daily habit and watch your streak grow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700])),
          ),
          SizedBox(height: 14),
          TextButton(
            onPressed: onAddTap,
            child: Text('Add your first habit',
                style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}
