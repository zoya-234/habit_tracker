import 'dart:convert';

class Habit {
  final String id;
  String name;
  String category;
  int goalDays;
  bool completedToday;
  int streak;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    this.goalDays = 0,
    this.completedToday = false,
    this.streak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'goalDays': goalDays,
      'completedToday': completedToday ? 1 : 0,
      'streak': streak,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      goalDays: map['goalDays'] ?? 0,
      completedToday: (map['completedToday'] ?? 0) == 1,
      streak: map['streak'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));
}
