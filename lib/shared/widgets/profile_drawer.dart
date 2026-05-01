import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:dragon/features/profile/screens/profile_screen.dart';
import 'package:dragon/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final email = vm.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: CatppuccinMocha.mantle,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile header ────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color.fromRGBO(203, 166, 247, 0.2),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: CatppuccinMocha.mauve,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      email,
                      style: const TextStyle(
                        color: CatppuccinMocha.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text(
                          'View your profile',
                          style: TextStyle(
                            color: CatppuccinMocha.mauve,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: CatppuccinMocha.mauve,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Divider(color: CatppuccinMocha.surface1, height: 1),

            const SizedBox(height: 8),

            // ── Menu items ────────────────────────────────────────────────
            ListTile(
              leading: SvgPicture.asset(
                'assets/images/settings.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  CatppuccinMocha.subtext0,
                  BlendMode.srcIn,
                ),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(color: CatppuccinMocha.text),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            Divider(color: CatppuccinMocha.surface1, height: 1),

            // ── Logout ────────────────────────────────────────────────────
            ListTile(
              leading: SvgPicture.asset(
                'assets/images/logout.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  CatppuccinMocha.red,
                  BlendMode.srcIn,
                ),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: CatppuccinMocha.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthViewModel>().logout();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
