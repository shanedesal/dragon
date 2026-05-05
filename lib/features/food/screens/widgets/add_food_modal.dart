// ------------------------------------------------------------------
// File: add_food_modal.dart
// Feature: Food
// Description: A bottom sheet UI for users to punch in a new food.
// ------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../viewmodels/food_viewmodel.dart';

class AddFoodModal extends StatefulWidget {
  const AddFoodModal({super.key});

  static void show(BuildContext context) {
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
        child: const AddFoodModal(),
      ),
    );
  }

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _servingController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final calories = int.parse(_caloriesController.text.trim());
      final serving = _servingController.text.trim();

      context.read<FoodViewModel>().addFoodEntry(name, calories, serving);
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
              'Log Food',
              style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
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
              controller: _servingController,
              decoration: const InputDecoration(
                labelText: 'Serving Size (e.g. 1 bowl, 200g)',
                prefixIcon: Icon(Icons.scale),
              ),
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
              child: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
