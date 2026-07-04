import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF26215C);
  static const primaryLight = Color(0xFF3C3489);
  static const accent = Color(0xFFF2A93B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const background = Color(0xFFF7F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E4DF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B6B7B);
  static const textMuted = Color(0xFF9B9AA5);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // NOTE: Size.fromHeight(52) sets minimum WIDTH to double.infinity,
          // not just height. That's invisible on buttons inside a stretched
          // Column (login/pay screens), but inside a bounded, non-stretching
          // context like ListTile.trailing it corrupts layout — Flutter web
          // renders affected Text widgets one character per line. Use a
          // finite minimum width instead; full-width buttons still get their
          // width from the enclosing stretched Column, not from this.
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 0.5),
          // See the note on filledButtonTheme above — Size.fromHeight sets
          // minimum width to infinity, which breaks ListTile.trailing layout.
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerColor: AppColors.border,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.forStatus(String status) {
    switch (status) {
      case 'paid':
      case 'resolved':
      case 'approved':
      case 'checked_in':
      case 'booked':
        return StatusBadge(label: _sentenceCase(status), color: AppColors.success);
      case 'partial':
      case 'in_progress':
      case 'due_soon':
      case 'pending':
      case 'checked_out':
        return StatusBadge(label: _sentenceCase(status), color: AppColors.warning);
      case 'overdue':
      case 'open':
      case 'denied':
      case 'active':
      case 'cancelled':
        return StatusBadge(label: _sentenceCase(status), color: AppColors.danger);
      default:
        return StatusBadge(label: _sentenceCase(status), color: AppColors.textSecondary);
    }
  }

  static String _sentenceCase(String s) {
    final withSpaces = s.replaceAll('_', ' ');
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
