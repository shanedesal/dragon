import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CatppuccinMocha.surface0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CatppuccinMocha.surface1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(203, 166, 247, 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: CatppuccinMocha.mauve,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: CatppuccinMocha.subtext0,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'User',
                          style: const TextStyle(
                            color: CatppuccinMocha.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(166, 227, 161, 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color.fromRGBO(166, 227, 161, 0.35),
                      ),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: CatppuccinMocha.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'More content coming soon.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const Expanded(child: Center(child: _EmptyState())),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color.fromRGBO(203, 166, 247, 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color.fromRGBO(203, 166, 247, 0.2)),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: CatppuccinMocha.mauve,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're all set!",
          style: TextStyle(
            color: CatppuccinMocha.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nothing to do right now.',
          style: TextStyle(color: CatppuccinMocha.subtext0, fontSize: 13),
        ),
      ],
    );
  }
}
