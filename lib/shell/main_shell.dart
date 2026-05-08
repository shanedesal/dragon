// ------------------------------------------------------------------
// File: main_shell.dart
// Feature: Shell
// Description: Root scaffold that owns the bottom navigation bar and
//              switches between the Home, Food, and Walk tabs.
// ------------------------------------------------------------------
import 'package:dragon/features/food/screens/food_tab.dart';
import 'package:dragon/features/home/screens/home_tab.dart';
import 'package:dragon/features/walk/screens/walk_tab.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:dragon/shell/navigation_viewmodel.dart';
import 'package:dragon/shared/widgets/profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _tabs = [HomeTab(), FoodTab(), WalkTab()];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationViewModel>().currentIndex;

    return Scaffold(
      appBar: AppBar(
        leading: const _ProfileAvatarButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/images/logo.svg', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('Dragon'),
          ],
        ),
        centerTitle: true,
      ),
      drawer: const ProfileDrawer(),
      body: _tabs[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
            context.read<NavigationViewModel>().setIndex(i),
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/images/nav_home.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.overlay1,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/images/nav_home.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.mauve,
                BlendMode.srcIn,
              ),
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/images/nav_food.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.overlay1,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/images/nav_food.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.mauve,
                BlendMode.srcIn,
              ),
            ),
            label: 'Food',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/images/nav_walk.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.overlay1,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/images/nav_walk.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                CatppuccinMocha.mauve,
                BlendMode.srcIn,
              ),
            ),
            label: 'Walk',
          ),
        ],
      ),
    );
  }
}

/// Renders the user's initial letter inside a circular avatar.
/// Opens the [ProfileDrawer] when tapped.
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return IconButton(
      tooltip: 'Profile',
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: CatppuccinMocha.mauve.withValues(alpha: 0.2),
        child: Text(
          initial,
          style: const TextStyle(
            color: CatppuccinMocha.mauve,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
