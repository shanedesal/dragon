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
  FoodEntry? _selectedCatalogEntry;

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

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

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

  void _applyCatalogEntry(FoodEntry entry) {
    setState(() {
      _selectedCatalogEntry = entry;
      _nameController.text = entry.name;
      _quantityController.text = entry.quantity.toString();
      _selectedUnit = entry.unit;
      _caloriesPerUnitController.text = entry.caloriesPerUnit.toString();
      _proteinPerUnitController.text = entry.proteinPerUnit.toString();
      _carbsPerUnitController.text = entry.carbsPerUnit.toString();
      _fatPerUnitController.text = entry.fatPerUnit.toString();
    });
    AppLogger.d('FoodUI', 'Catalog entry selected: ${entry.name}');
  }

  void _clearCatalogSelection() {
    if (_selectedCatalogEntry == null) return;
    setState(() => _selectedCatalogEntry = null);
    AppLogger.d('FoodUI', 'Catalog selection cleared');
  }

  Future<void> _autoFill() async {
    final name = _nameController.text.trim();
    final quantity = _parseInt(_quantityController.text);

    if (name.isEmpty || quantity <= 0) {
      _showInfoDialog(
        'Enter a food name before auto-filling and include number of '
        'servings if possible (e.g. "2 eggs", "150g chicken").',
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

    final autoFilledEntry =
        await context.read<FoodViewModel>().autoFillFoodEntry(entry);
    AppLogger.d('FoodUI', 'Autofill requested for "$name"');

    if (!mounted) return;

    if (autoFilledEntry == null) {
      _showInfoDialog(
        'Sorry, no data found for that food. '
        'Try being more specific (e.g. "2 eggs", "150g chicken").',
      );
      return;
    }

    setState(() {
      _caloriesPerUnitController.text =
          autoFilledEntry.caloriesPerUnit.toString();
      _proteinPerUnitController.text =
          autoFilledEntry.proteinPerUnit.toString();
      _carbsPerUnitController.text = autoFilledEntry.carbsPerUnit.toString();
      _fatPerUnitController.text = autoFilledEntry.fatPerUnit.toString();
    });
    AppLogger.d(
      'FoodUI',
      'Autofill successful for "$name": '
          '${autoFilledEntry.caloriesPerUnit} kcal/unit, '
          '${autoFilledEntry.proteinPerUnit} g protein/unit, '
          '${autoFilledEntry.carbsPerUnit} g carbs/unit, '
          '${autoFilledEntry.fatPerUnit} g fat/unit',
    );
  }

  /// Shows a themed info dialog. Extracted to avoid duplicated AlertDialog code.
  void _showInfoDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CatppuccinMocha.surface0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: CatppuccinMocha.text,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: CatppuccinMocha.mauve),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();
    final quantity = _parseInt(_quantityController.text);
    final caloriesPerUnit = _parseInt(_caloriesPerUnitController.text);
    final proteinPerUnit = _parseInt(_proteinPerUnitController.text);
    final carbsPerUnit = _parseInt(_carbsPerUnitController.text);
    final fatPerUnit = _parseInt(_fatPerUnitController.text);
    final totalCalories = quantity * caloriesPerUnit;
    final totalProtein = quantity * proteinPerUnit;
    final totalCarbs = quantity * carbsPerUnit;
    final totalFat = quantity * fatPerUnit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (title + autofill button) ──────────────────────────
            _ModalHeader(
              isAutoFilling: vm.isAutoFilling,
              onAutoFill: _autoFill,
            ),
            const SizedBox(height: 20),

            // ── Selected catalog chip ──────────────────────────────────────
            if (_selectedCatalogEntry != null) ...[
              _CatalogBanner(
                entry: _selectedCatalogEntry!,
                onClear: _clearCatalogSelection,
              ),
              const SizedBox(height: 16),
            ],

            // ── Saved foods list ───────────────────────────────────────────
            _CatalogSection(
              catalogEntries: vm.catalogEntries,
              selectedCatalogEntry: _selectedCatalogEntry,
              onEntrySelected: _applyCatalogEntry,
            ),
            const SizedBox(height: 20),

            // ── Name field ─────────────────────────────────────────────────
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

            // ── Quantity + unit row ────────────────────────────────────────
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

            // ── Advanced macros (calories, protein, carbs, fat + preview) ──
            _MacroFields(
              caloriesController: _caloriesPerUnitController,
              proteinController: _proteinPerUnitController,
              carbsController: _carbsPerUnitController,
              fatController: _fatPerUnitController,
              selectedUnit: _selectedUnit,
              totalCalories: totalCalories,
              totalProtein: totalProtein,
              totalCarbs: totalCarbs,
              totalFat: totalFat,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── Submit ─────────────────────────────────────────────────────
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

// ── Modal header ──────────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  final bool isAutoFilling;
  final VoidCallback onAutoFill;

  const _ModalHeader({required this.isAutoFilling, required this.onAutoFill});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            onPressed: isAutoFilling ? null : onAutoFill,
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
    );
  }
}

// ── Catalog banner (selected food chip) ──────────────────────────────────────

class _CatalogBanner extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onClear;

  const _CatalogBanner({required this.entry, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: CatppuccinMocha.mauve),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Using ${entry.name} from your catalog',
              style: const TextStyle(color: CatppuccinMocha.text),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Clear catalog selection',
          ),
        ],
      ),
    );
  }
}

// ── Catalog section (expansion tile + scrollable list) ────────────────────────

class _CatalogSection extends StatelessWidget {
  final List<FoodEntry> catalogEntries;
  final FoodEntry? selectedCatalogEntry;
  final ValueChanged<FoodEntry> onEntrySelected;

  const _CatalogSection({
    required this.catalogEntries,
    required this.selectedCatalogEntry,
    required this.onEntrySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      onExpansionChanged: (expanded) {
        AppLogger.d(
          'FoodUI',
          expanded ? 'Catalog expanded' : 'Catalog collapsed',
        );
      },
      title: const Text(
        'Saved foods',
        style: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        catalogEntries.isEmpty ? 'No saved foods yet' : 'Tap one to fill the form',
        style: const TextStyle(color: CatppuccinMocha.subtext0),
      ),
      children: [
        if (catalogEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Your saved foods will appear here after you log a few meals.',
              style: TextStyle(color: CatppuccinMocha.subtext0, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              itemCount: catalogEntries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = catalogEntries[index];
                return _CatalogTile(
                  entry: entry,
                  isSelected: selectedCatalogEntry?.name == entry.name,
                  onTap: () => onEntrySelected(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Single catalog tile ───────────────────────────────────────────────────────

class _CatalogTile extends StatelessWidget {
  final FoodEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatalogTile({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CatppuccinMocha.surface0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? CatppuccinMocha.mauve : CatppuccinMocha.surface1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: CatppuccinMocha.mauve.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 18,
                  color: CatppuccinMocha.mauve,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        color: CatppuccinMocha.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.quantity} ${entry.unit} • ${entry.totalCalories} kcal',
                      style: const TextStyle(
                        color: CatppuccinMocha.subtext0,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CatppuccinMocha.subtext0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Macro fields (expansion tile with inputs + totals preview) ────────────────

class _MacroFields extends StatelessWidget {
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final String selectedUnit;
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final VoidCallback onChanged;

  const _MacroFields({
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.selectedUnit,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      onExpansionChanged: (expanded) {
        AppLogger.d(
          'FoodUI',
          expanded ? 'Advanced macros expanded' : 'Advanced macros collapsed',
        );
      },
      title: const Text(
        'Advanced macros',
        style: TextStyle(
          color: CatppuccinMocha.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Calories, protein, carbs, and fat',
        style: TextStyle(color: CatppuccinMocha.subtext0),
      ),
      children: [
        TextFormField(
          controller: caloriesController,
          decoration: InputDecoration(
            labelText: 'Calories per unit',
            prefixIcon: const Icon(Icons.local_fire_department),
            suffixText: 'kcal / $selectedUnit',
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
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: proteinController,
          decoration: InputDecoration(
            labelText: 'Protein per unit',
            prefixIcon: const Icon(Icons.fitness_center),
            suffixText: 'g / $selectedUnit',
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: CatppuccinMocha.text),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            if (int.tryParse(value) == null) return 'Must be a number';
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: carbsController,
          decoration: InputDecoration(
            labelText: 'Carbs per unit',
            prefixIcon: const Icon(Icons.rice_bowl),
            suffixText: 'g / $selectedUnit',
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: CatppuccinMocha.text),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            if (int.tryParse(value) == null) return 'Must be a number';
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fatController,
          decoration: InputDecoration(
            labelText: 'Fat per unit',
            prefixIcon: const Icon(Icons.opacity),
            suffixText: 'g / $selectedUnit',
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: CatppuccinMocha.text),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            if (int.tryParse(value) == null) return 'Must be a number';
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        _TotalsPreview(
          totalCalories: totalCalories,
          totalProtein: totalProtein,
          totalCarbs: totalCarbs,
          totalFat: totalFat,
        ),
      ],
    );
  }
}

// ── Totals preview row ────────────────────────────────────────────────────────

class _TotalsPreview extends StatelessWidget {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;

  const _TotalsPreview({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(color: CatppuccinMocha.subtext0, fontSize: 12),
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
    );
  }
}
