import 'package:dragon/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CatppuccinMocha.base,
      appBar: AppBar(
        backgroundColor: CatppuccinMocha.mantle,
        foregroundColor: CatppuccinMocha.text,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: CatppuccinMocha.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}