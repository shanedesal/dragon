// ------------------------------------------------------------------
// File: set_goals_modal.dart
// Feature: Food
// Description: A modal for users to update their daily food goals.
// ------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../theme/app_theme.dart';
import '../../viewmodels/food_viewmodel.dart';

class SetGoalsModal extends StatefulWidget {
  const SetGoalsModal({super.key});

  static void show(BuildContext context) {
    AppLogger.d('FoodGoals', 'Open SetGoalsModal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CatppuccinMocha.base,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const SetGoalsModal(),
      ),
    );
  }

  @override
  State<SetGoalsModal> createState() => _SetGoalsModalState();
}

class _SetGoalsModalState extends State<SetGoalsModal> {
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final goals = context.read<FoodViewModel>().dailyGoals;
    _caloriesController.text = goals.targetCalories.toString();
    _proteinController.text = goals.targetProtein.toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final calories = int.parse(_caloriesController.text.trim());
      final protein = int.parse(_proteinController.text.trim());

      AppLogger.d(
        'FoodGoals',
        'Save goals: $calories kcal / $protein g protein',
      );
      context.read<FoodViewModel>().updateDailyGoals(calories, protein);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set Daily Goals',
              style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Target Calories (kcal)',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Target Protein (g)',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: CatppuccinMocha.mauve,
                foregroundColor: CatppuccinMocha.crust,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Goals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
