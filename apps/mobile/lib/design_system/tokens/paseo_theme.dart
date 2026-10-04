import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Tema global de Flutter configurado con los tokens de Paseo Points.
abstract final class PaseoTheme {
  /// Tema oscuro Obsidian Gold para clientes VIP.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PaseoColors.obsidianBlack,
      primaryColor: PaseoColors.goldPrimary,
      canvasColor: PaseoColors.obsidianDark,
      colorScheme: const ColorScheme.dark(
        primary: PaseoColors.goldPrimary,
        secondary: PaseoColors.goldMetallic,
        surface: PaseoColors.surfaceCard,
        error: PaseoColors.ruby,
        onPrimary: PaseoColors.obsidianBlack,
        onSecondary: PaseoColors.obsidianBlack,
        onSurface: PaseoColors.textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: PaseoTypography.screenTitle,
        iconTheme: IconThemeData(color: PaseoColors.textWhite),
      ),
      cardTheme: CardThemeData(
        color: PaseoColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: PaseoColors.surfaceBorder),
        ),
      ),
      iconTheme: const IconThemeData(color: PaseoColors.textWhite, size: 24),
      splashColor: PaseoColors.goldPrimary.withValues(alpha: 0.1),
      highlightColor: PaseoColors.goldPrimary.withValues(alpha: 0.05),
    );
  }
}
