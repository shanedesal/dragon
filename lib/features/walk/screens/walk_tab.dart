// ------------------------------------------------------------------
// File: walk_tab.dart
// Feature: Walk
// Description: Walk tab UI for step tracking, goal editing, and history.
// ------------------------------------------------------------------

import 'package:dragon/features/walk/models/day_steps.dart';
import 'package:dragon/features/walk/viewmodels/walk_viewmodel.dart';
import 'package:dragon/shared/utils/app_logger.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ── WalkTab ─────────────────────────────────────────────────────────────────-

class WalkTab extends StatefulWidget {
  const WalkTab({super.key});

  @override
  State<WalkTab> createState() => _WalkTabState();
}

class _WalkTabState extends State<WalkTab> {
  @override
  void initState() {
    super.initState();
    // Kick off permission + sensor init the first time this tab is shown.
    // Uses addPostFrameCallback so context.read is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('WalkUI', 'WalkTab mounted, calling initTracking');
      context.read<WalkViewModel>().initTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalkViewModel>();

    if (!vm.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(CatppuccinMocha.mauve),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.d('WalkUI', 'Pull-to-refresh');
        await vm.refreshHistory();
      },
      color: CatppuccinMocha.mauve,
      backgroundColor: CatppuccinMocha.surface0,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (vm.isWeb) ...[
                  _WebUnavailableBanner(),
                ] else ...[
                  _StepRingCard(vm: vm),
                  const SizedBox(height: 16),
                  _GoalCard(vm: vm),
                ],
                const SizedBox(height: 24),
                _HistorySection(vm: vm),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Web unavailable banner ───────────────────────────────────────────────────-

class _WebUnavailableBanner extends StatelessWidget {
  const _WebUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.phone_android_rounded,
            color: CatppuccinMocha.mauve,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Step tracking isn\'t available on web.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CatppuccinMocha.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Open Dragon on your phone or tablet\nto track your daily steps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CatppuccinMocha.subtext0, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Step ring card ─────────────────────────────────────────────────────────---

class _StepRingCard extends StatelessWidget {
  final WalkViewModel vm;
  const _StepRingCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final progress = (vm.todaySteps / vm.stepGoal).clamp(0.0, 1.0);
    final goalReached = progress >= 1.0;
    final ringColor = goalReached
        ? CatppuccinMocha.green
        : CatppuccinMocha.mauve;
    final isWalking = vm.status == 'walking';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Column(
        children: [
          // ── Progress ring ─────────────────────────────────────────────
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CatppuccinMocha.surface1,
                    ),
                  ),
                ),
                // Actual progress
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.todaySteps.toString(),
                      style: const TextStyle(
                        color: CatppuccinMocha.text,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'steps',
                      style: TextStyle(
                        color: CatppuccinMocha.subtext0,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Percentage label ─────────────────────────────────────────-
          Text(
            goalReached
                ? 'Goal reached! 🎉'
                : '${(progress * 100).toStringAsFixed(0)}% of goal',
            style: TextStyle(
              color: ringColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // ── Walking status badge ─────────────────────────────────────-
          _StatusBadge(isWalking: isWalking),

          // ── Permission warning ───────────────────────────────────────-
          if (!vm.hasPermission) ...[
            const SizedBox(height: 14),
            _PermissionBanner(),
          ],
        ],
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────----

class _StatusBadge extends StatelessWidget {
  final bool isWalking;
  const _StatusBadge({required this.isWalking});

  @override
  Widget build(BuildContext context) {
    final color = isWalking ? CatppuccinMocha.green : CatppuccinMocha.overlay1;
    final bgColor = isWalking
        ? const Color.fromRGBO(166, 227, 161, 0.15)
        : const Color.fromRGBO(127, 132, 156, 0.1);
    final borderColor = isWalking
        ? const Color.fromRGBO(166, 227, 161, 0.35)
        : const Color.fromRGBO(127, 132, 156, 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalking
                ? Icons.directions_walk_rounded
                : Icons.pause_circle_outline_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isWalking ? 'Walking' : 'Still',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission banner ─────────────────────────────────────────────────--------

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(243, 139, 168, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(243, 139, 168, 0.3)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: CatppuccinMocha.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Motion permission is needed to count steps. '
              'Please grant it in your device settings.',
              style: TextStyle(color: CatppuccinMocha.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────----------------

class _GoalCard extends StatelessWidget {
  final WalkViewModel vm;
  const _GoalCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: CatppuccinMocha.mauve,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Goal',
                  style: TextStyle(
                    color: CatppuccinMocha.subtext0,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vm.stepGoal} steps',
                  style: const TextStyle(
                    color: CatppuccinMocha.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: CatppuccinMocha.overlay2,
              size: 20,
            ),
            tooltip: 'Edit goal',
            onPressed: () => _showGoalDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalDialog(BuildContext context) async {
    AppLogger.d('WalkUI', 'Open goal dialog');
    final controller = TextEditingController(text: vm.stepGoal.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.surface0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        title: const Text(
          'Set Daily Goal',
          style: TextStyle(color: CatppuccinMocha.text),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: CatppuccinMocha.text),
          decoration: const InputDecoration(
            hintText: 'e.g. 10000',
            suffixText: 'steps',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CatppuccinMocha.overlay2),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) Navigator.of(ctx).pop(val);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: CatppuccinMocha.mauve),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      AppLogger.d('WalkUI', 'Goal dialog saved: $result');
      // Read fresh from context after async gap — avoids stale constructor ref.
      if (context.mounted) await context.read<WalkViewModel>().setGoal(result);
    } else {
      AppLogger.d('WalkUI', 'Goal dialog canceled');
    }
  }
}

// ── History section ─────────────────────────────────────────────────---------

class _HistorySection extends StatelessWidget {
  final WalkViewModel vm;
  const _HistorySection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final history = vm.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: CatppuccinMocha.subtext0,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'History',
              style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CatppuccinMocha.surface0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CatppuccinMocha.surface1),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  color: CatppuccinMocha.overlay0,
                  size: 32,
                ),
                SizedBox(height: 10),
                Text(
                  'No history yet.',
                  style: TextStyle(
                    color: CatppuccinMocha.subtext1,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start walking — your daily steps\nwill appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CatppuccinMocha.subtext0,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...history.map((day) => _HistoryItem(day: day)),
      ],
    );
  }
}

// ── History item ─────────────────────────────────────────────────-----------

class _HistoryItem extends StatelessWidget {
  final DaySteps day;
  const _HistoryItem({required this.day});

  @override
  Widget build(BuildContext context) {
    final achieved = day.steps >= day.goal;
    final progress = (day.steps / day.goal).clamp(0.0, 1.0);
    final progressColor = achieved
        ? CatppuccinMocha.green
        : CatppuccinMocha.mauve;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatppuccinMocha.surface0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: achieved
                  ? const Color.fromRGBO(166, 227, 161, 0.15)
                  : const Color.fromRGBO(127, 132, 156, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              achieved
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: achieved
                  ? CatppuccinMocha.green
                  : CatppuccinMocha.overlay1,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          // Date + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(day.date),
                  style: const TextStyle(
                    color: CatppuccinMocha.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: CatppuccinMocha.surface1,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Step count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                day.steps.toString(),
                style: TextStyle(
                  color: achieved
                      ? CatppuccinMocha.green
                      : CatppuccinMocha.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '/ ${day.goal}',
                style: const TextStyle(
                  color: CatppuccinMocha.subtext0,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d = DateTime(date.year, date.month, date.day);

      if (d == today) return 'Today';
      if (d == yesterday) return 'Yesterday';

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
