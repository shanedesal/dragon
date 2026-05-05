import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/food/models/food_entry.dart';
import 'package:dragon/features/food/viewmodels/food_viewmodel.dart';
import 'package:dragon/features/food/screens/widgets/add_food_modal.dart';
import 'package:dragon/features/food/screens/widgets/set_goals_modal.dart';
import 'package:dragon/shared/utils/app_logger.dart';
import 'package:dragon/shared/widgets/error_banner.dart';

class FoodTab extends StatelessWidget {
  const FoodTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();
    final calorieGoal = vm.dailyGoals.targetCalories;
    final proteinGoal = vm.dailyGoals.targetProtein;

    return Scaffold(
      body: SafeArea(
        child: vm.isLoading && vm.dailyEntries.isEmpty
            ? const Center(child: CircularProgressIndicator(color: CatppuccinMocha.mauve))
            : RefreshIndicator(
                color: CatppuccinMocha.mauve,
                onRefresh: () async {
                  AppLogger.d('FoodUI', 'Pull-to-refresh');
                  await vm.fetchFoodData();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (vm.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ErrorBannerWidget(message: vm.errorMessage!),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track calories and macros in one place.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryCard(
                              context,
                              vm,
                              calorieGoal,
                              proteinGoal,
                            ),
                            const SizedBox(height: 20),
                            _buildMacroCard(vm),
                            const SizedBox(height: 28),
                            Text(
                              'Today\'s Entries',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (vm.dailyEntries.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyFoodState(
                          onAddPressed: () => AddFoodModal.show(context),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = vm.dailyEntries[index];
                              return _FoodEntryCard(
                                entry: entry,
                                onDelete: () => vm.deleteFoodEntry(entry.id),
                              );
                            },
                            childCount: vm.dailyEntries.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)), // FAB padding
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddFoodModal.show(context),
        backgroundColor: CatppuccinMocha.mauve,
        child: const Icon(Icons.add, color: CatppuccinMocha.crust),
      ),
    );
  }
}

class _EmptyFoodState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyFoodState({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(203, 166, 247, 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color.fromRGBO(203, 166, 247, 0.2)),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: CatppuccinMocha.mauve,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No food logged yet',
              style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start tracking your meals and macros.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CatppuccinMocha.subtext0,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Log your first meal'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSummaryCard(
  BuildContext context,
  FoodViewModel vm,
  int calorieGoal,
  int proteinGoal,
) {
  final calorieProgress =
      calorieGoal > 0 ? vm.totalCalories / calorieGoal : 0.0;
  final proteinProgress =
      proteinGoal > 0 ? vm.totalProtein / proteinGoal : 0.0;
  final caloriesRemaining = max(0, calorieGoal - vm.totalCalories);
  final proteinRemaining = max(0, proteinGoal - vm.totalProtein);
  final calorieColor =
      calorieProgress >= 1.0 ? CatppuccinMocha.red : CatppuccinMocha.mauve;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: CatppuccinMocha.surface0,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CatppuccinMocha.surface1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: CatppuccinMocha.subtext0),
              onPressed: () => SetGoalsModal.show(context),
              tooltip: 'Edit goals',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${vm.totalCalories} kcal',
          style: const TextStyle(
            color: CatppuccinMocha.text,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$caloriesRemaining kcal remaining',
          style: const TextStyle(
            color: CatppuccinMocha.subtext0,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _ProgressRow(
          label: 'Calories',
          current: vm.totalCalories,
          goal: calorieGoal,
          progress: calorieProgress,
          color: calorieColor,
          unit: 'kcal',
        ),
        const SizedBox(height: 12),
        _ProgressRow(
          label: 'Protein',
          current: vm.totalProtein,
          goal: proteinGoal,
          progress: proteinProgress,
          color: CatppuccinMocha.blue,
          unit: 'g',
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goal: $calorieGoal kcal',
              style: const TextStyle(
                color: CatppuccinMocha.subtext0,
                fontSize: 12,
              ),
            ),
            Text(
              '$proteinRemaining g protein remaining',
              style: const TextStyle(
                color: CatppuccinMocha.subtext0,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final double progress;
  final Color color;
  final String unit;

  const _ProgressRow({
    required this.label,
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CatppuccinMocha.subtext0,
                fontSize: 12,
              ),
            ),
            Text(
              '$current / $goal $unit',
              style: const TextStyle(
                color: CatppuccinMocha.subtext0,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: CatppuccinMocha.surface1,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

Widget _buildMacroCard(FoodViewModel vm) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CatppuccinMocha.surface0,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CatppuccinMocha.surface1),
    ),
    child: Row(
      children: [
        Expanded(
          child: _MacroStat(
            label: 'Protein',
            value: '${vm.totalProtein} g',
            icon: Icons.fitness_center,
            color: CatppuccinMocha.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroStat(
            label: 'Carbs',
            value: '${vm.totalCarbs} g',
            icon: Icons.rice_bowl,
            color: CatppuccinMocha.yellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroStat(
            label: 'Fat',
            value: '${vm.totalFat} g',
            icon: Icons.opacity,
            color: CatppuccinMocha.peach,
          ),
        ),
      ],
    ),
  );
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MacroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: CatppuccinMocha.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryCard extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;

  const _FoodEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(203, 166, 247, 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: CatppuccinMocha.mauve,
              size: 20,
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatServing(entry),
                  style: const TextStyle(
                    color: CatppuccinMocha.subtext0,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P ${entry.totalProtein} g • C ${entry.totalCarbs} g • F ${entry.totalFat} g',
                  style: const TextStyle(
                    color: CatppuccinMocha.subtext1,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalCalories} kcal',
                style: const TextStyle(
                  color: CatppuccinMocha.mauve,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(entry.timestamp),
                style: const TextStyle(
                  color: CatppuccinMocha.subtext0,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: CatppuccinMocha.red),
            onPressed: onDelete,
            tooltip: 'Delete Entry',
          ),
        ],
      ),
    );
  }

  String _formatServing(FoodEntry entry) {
    final unit = entry.unit.trim();
    if (unit.isEmpty) return '${entry.quantity} serving';
    if (entry.quantity == 1 && unit.startsWith('1 ')) return unit;
    if (RegExp(r'^\d').hasMatch(unit)) return unit;
    return '${entry.quantity} $unit';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

