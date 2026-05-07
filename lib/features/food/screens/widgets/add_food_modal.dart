// ------------------------------------------------------------------
// File: add_food_modal.dart
// Feature: Food
// Description: A bottom sheet UI for users to punch in a new food.
// ------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../theme/app_theme.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../models/food_entry.dart';

class AddFoodModal extends StatefulWidget {
  const AddFoodModal({super.key});

  static void show(BuildContext context) {
    AppLogger.d('FoodUI', 'Open AddFoodModal');
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
  static const List<String> _unitOptions = [
    'g',
    'ml',
    'serving',
    'piece',
    'cup',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _caloriesPerUnitController = TextEditingController();
  final _proteinPerUnitController = TextEditingController();
  final _carbsPerUnitController = TextEditingController();
  final _fatPerUnitController = TextEditingController();
  String _selectedUnit = _unitOptions.first;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesPerUnitController.dispose();
    _proteinPerUnitController.dispose();
    _carbsPerUnitController.dispose();
    _fatPerUnitController.dispose();
    super.dispose();
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppLogger.d('FoodUI', 'Add food validation failed');
      return;
    }

    final name = _nameController.text.trim();
    final quantity = _parseInt(_quantityController.text);
    final caloriesPerUnit = _parseInt(_caloriesPerUnitController.text);
    final proteinPerUnit = _parseInt(_proteinPerUnitController.text);
    final carbsPerUnit = _parseInt(_carbsPerUnitController.text);
    final fatPerUnit = _parseInt(_fatPerUnitController.text);
    final totalCalories = quantity * caloriesPerUnit;
    final totalProtein = quantity * proteinPerUnit;
    final totalCarbs = quantity * carbsPerUnit;
    final totalFat = quantity * fatPerUnit;

    AppLogger.d(
      'FoodUI',
      'Submit food: $name qty=$quantity unit=$_selectedUnit '
          'kcal=$totalCalories p=$totalProtein c=$totalCarbs f=$totalFat',
    );
    context.read<FoodViewModel>().addFoodEntry(
      name,
      quantity,
      _selectedUnit,
      caloriesPerUnit,
      proteinPerUnit,
      carbsPerUnit,
      fatPerUnit,
    );
    Navigator.of(context).pop();
  }

  Future<void> _autoFill() async {
  final name = _nameController.text.trim();
  final quantity = _parseInt(_quantityController.text);

  if (name.isEmpty || quantity <= 0) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
          'Enter a food name before auto-filling and include number of servings if possible (e.g. "2 eggs", "150g chicken").',
          style: TextStyle(
            color: CatppuccinMocha.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: CatppuccinMocha.mauve)),
          ),
        ],
      ),
    );
    AppLogger.d('FoodUI', 'Autofill failed: empty name / invalid quantity');
    return;
  }

  final entry = FoodEntry(
    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    name: name,
    quantity: quantity,
    unit: _selectedUnit,
    caloriesPerUnit: 0,
    proteinPerUnit: 0,
    carbsPerUnit: 0,
    fatPerUnit: 0,
    totalCalories: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    timestamp: DateTime.now(),
  );

  final autoFilledEntry = await context.read<FoodViewModel>().autoFillFoodEntry(entry);
  AppLogger.d('FoodUI', 'Autofill requested for "$name"');

  if (!mounted) return;

  if (autoFilledEntry == null) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
          'Sorry, no data found for that food. Try being more specific (e.g. "2 eggs", "150g chicken").',
          style: TextStyle(
            color: CatppuccinMocha.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: CatppuccinMocha.mauve)),
          ),
        ],
      ),
    );
    return;
  }

  setState(() {
    _caloriesPerUnitController.text = autoFilledEntry.caloriesPerUnit.toString();
    _proteinPerUnitController.text = autoFilledEntry.proteinPerUnit.toString();
    _carbsPerUnitController.text = autoFilledEntry.carbsPerUnit.toString();
    _fatPerUnitController.text = autoFilledEntry.fatPerUnit.toString();
    AppLogger.d(
      'FoodUI',
      'Autofill successful for "$name": '
          '${autoFilledEntry.caloriesPerUnit} kcal/unit, '
          '${autoFilledEntry.proteinPerUnit} g protein/unit, '
          '${autoFilledEntry.carbsPerUnit} g carbs/unit, '
          '${autoFilledEntry.fatPerUnit} g fat/unit',
    );
  });
}

  @override
  Widget build(BuildContext context) {
    final quantity = _parseInt(_quantityController.text);
    final caloriesPerUnit = _parseInt(_caloriesPerUnitController.text);
    final proteinPerUnit = _parseInt(_proteinPerUnitController.text);
    final carbsPerUnit = _parseInt(_carbsPerUnitController.text);
    final fatPerUnit = _parseInt(_fatPerUnitController.text);
    final totalCalories = quantity * caloriesPerUnit;
    final totalProtein = quantity * proteinPerUnit;
    final totalCarbs = quantity * carbsPerUnit;
    final totalFat = quantity * fatPerUnit;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Log Food',
                    style: TextStyle(
                      color: CatppuccinMocha.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: context.watch<FoodViewModel>().isAutoFilling ? null 
                    : _autoFill,
                    icon: SvgPicture.asset(
                      'assets/images/auto_fill.svg',
                      height: 24,
                      width: 24,
                      colorFilter: const ColorFilter.mode(
                        CatppuccinMocha.mauve,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: CatppuccinMocha.text),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final parsed = int.tryParse(value);
                      if (parsed == null) return 'Must be a number';
                      if (parsed <= 0) return 'Must be at least 1';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                    dropdownColor: CatppuccinMocha.surface0,
                    items: _unitOptions
                        .map(
                          (unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedUnit = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesPerUnitController,
              decoration: InputDecoration(
                labelText: 'Calories per unit',
                prefixIcon: const Icon(Icons.local_fire_department),
                suffixText: 'kcal / $_selectedUnit',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final parsed = int.tryParse(value);
                if (parsed == null) return 'Must be a number';
                if (parsed <= 0) return 'Must be at least 1';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinPerUnitController,
              decoration: InputDecoration(
                labelText: 'Protein per unit',
                prefixIcon: const Icon(Icons.fitness_center),
                suffixText: 'g / $_selectedUnit',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carbsPerUnitController,
              decoration: InputDecoration(
                labelText: 'Carbs per unit',
                prefixIcon: const Icon(Icons.rice_bowl),
                suffixText: 'g / $_selectedUnit',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatPerUnitController,
              decoration: InputDecoration(
                labelText: 'Fat per unit',
                prefixIcon: const Icon(Icons.opacity),
                suffixText: 'g / $_selectedUnit',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CatppuccinMocha.text),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CatppuccinMocha.surface0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CatppuccinMocha.surface1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Totals',
                    style: TextStyle(
                      color: CatppuccinMocha.subtext0,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$totalCalories kcal • P $totalProtein g • C $totalCarbs g • F $totalFat g',
                    style: const TextStyle(
                      color: CatppuccinMocha.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                'Add Entry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
