import 'package:dragon/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ErrorBannerWidget extends StatelessWidget {
  const ErrorBannerWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(243, 139, 168, 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color.fromRGBO(243, 139, 168, 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: CatppuccinMocha.red,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CatppuccinMocha.red,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
