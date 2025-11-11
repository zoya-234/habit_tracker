import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

class AddHabitScreen extends StatefulWidget {
  // When editing, arguments will pass a map representing habit
  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  String _category = 'General';
  final List<String> _categories = [
    'General',
    'Health',
    'Study',
    'Productivity',
    'Hobby'
  ];
  late String _id;
  bool _isEdit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // check for passed habit (edit)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final h = Habit.fromMap(args);
      _id = h.id;
      _nameCtrl.text = h.name;
      _category = h.category;
      _goalCtrl.text = h.goalDays.toString();
      _isEdit = true;
    } else {
      _id = Uuid().v4();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final habit = Habit(
      id: _id,
      name: _nameCtrl.text.trim(),
      category: _category,
      goalDays: int.tryParse(_goalCtrl.text.trim()) ?? 0,
      completedToday: false,
      streak: 0,
    );
    Navigator.pop(context, habit.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'Add Habit'),
        elevation: 0,
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: isWide ? 120 : 20, vertical: 18),
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                          labelText: 'Habit name',
                          border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter a habit name'
                          : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: _categories
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'General'),
                      decoration: InputDecoration(
                          labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Goal days (optional)',
                          border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final n = int.tryParse(val.trim());
                        if (n == null || n < 0) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14.0),
                              child:
                                  Text(_isEdit ? 'Save changes' : 'Add Habit'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
