import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/food/viewmodels/food_viewmodel.dart';
import 'package:dragon/features/food/screens/widgets/add_food_modal.dart';
import 'package:dragon/features/food/screens/widgets/set_goals_modal.dart';
import 'package:dragon/shared/widgets/error_banner.dart';

class FoodTab extends StatelessWidget {
  const FoodTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FoodViewModel>();

    return Scaffold(
      body: SafeArea(
        child: vm.isLoading && vm.dailyEntries.isEmpty
            ? const Center(child: CircularProgressIndicator(color: CatppuccinMocha.mauve))
            : RefreshIndicator(
                color: CatppuccinMocha.mauve,
                onRefresh: () => vm.fetchFoodData(),
                child: CustomScrollView(
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
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Progress',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: CatppuccinMocha.subtext0),
                                  onPressed: () => SetGoalsModal.show(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressCard(context, vm),
                            const SizedBox(height: 32),
                            Text(
                              'Food Entries',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (vm.dailyEntries.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No food logged yet today.',
                            style: TextStyle(color: CatppuccinMocha.subtext0),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = vm.dailyEntries[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: CatppuccinMocha.surface0,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: CatppuccinMocha.surface1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.name,
                                          style: const TextStyle(
                                            color: CatppuccinMocha.text,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.servingSize,
                                          style: const TextStyle(
                                            color: CatppuccinMocha.subtext0,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${entry.calories} kcal',
                                          style: const TextStyle(
                                            color: CatppuccinMocha.mauve,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: CatppuccinMocha.red),
                                          onPressed: () => vm.deleteFoodEntry(entry.id),
                                          tooltip: 'Delete Entry',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildProgressCard(BuildContext context, FoodViewModel vm) {
    final caloriesLeft = vm.dailyGoals.targetCalories - vm.totalCalories;
    final progress = vm.totalCalories / (vm.dailyGoals.targetCalories > 0 ? vm.dailyGoals.targetCalories : 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CatppuccinMocha.surface1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Eaten', style: TextStyle(color: CatppuccinMocha.subtext0)),
                  Text(
                    '${vm.totalCalories}',
                    style: const TextStyle(
                      color: CatppuccinMocha.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Remaining', style: TextStyle(color: CatppuccinMocha.subtext0)),
                  Text(
                    '${caloriesLeft > 0 ? caloriesLeft : 0}',
                    style: const TextStyle(
                      color: CatppuccinMocha.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: CatppuccinMocha.surface1,
            color: progress >= 1.0 ? CatppuccinMocha.red : CatppuccinMocha.green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: ${vm.dailyGoals.targetCalories} kcal',
                style: const TextStyle(color: CatppuccinMocha.subtext0, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: CatppuccinMocha.subtext0, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

