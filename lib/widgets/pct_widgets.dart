import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PctLogoHeader extends StatelessWidget {
  const PctLogoHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: PctColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PctColors.gold, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text(
            'PCT',
            style: TextStyle(
              color: PctColors.gold,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PAK Cyber Team',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: PctColors.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(color: PctColors.muted, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class PctTextField extends StatelessWidget {
  const PctTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}

class PctErrorBanner extends StatelessWidget {
  const PctErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PctColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PctColors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: const TextStyle(color: PctColors.danger)),
    );
  }
}

class PctInfoBanner extends StatelessWidget {
  const PctInfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PctColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PctColors.success.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: const TextStyle(color: PctColors.success)),
    );
  }
}

/// Centered empty state for Firestore lists (never fake data).
class PctEmptyState extends StatelessWidget {
  const PctEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: PctColors.gold),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PctColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered error state with a retry button (e.g. Firestore unreachable).
class PctErrorState extends StatelessWidget {
  const PctErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: PctColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PctColors.text),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small gold chip used for format / level / difficulty labels.
class PctChip extends StatelessWidget {
  const PctChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PctColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PctColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: PctColors.gold),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: PctColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
