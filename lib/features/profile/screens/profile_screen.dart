import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: CatppuccinMocha.base,
      appBar: AppBar(
        backgroundColor: CatppuccinMocha.mantle,
        foregroundColor: CatppuccinMocha.text,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: CatppuccinMocha.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Color.fromRGBO(203, 166, 247, 0.15),
              child: Text(
                initial,
                style: const TextStyle(
                  color: CatppuccinMocha.mauve,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              email,
              style: const TextStyle(
                color: CatppuccinMocha.subtext1,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
