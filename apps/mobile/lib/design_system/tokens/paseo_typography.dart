import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Tipografías del sistema de diseño Paseo Points.
///
/// Combina fuentes Display de corte serif clásico para nombres y títulos
/// de prestigio, junto a fuentes Sans modernas para legibilidad óptima.
abstract final class PaseoTypography {
  /// Título serif display grande para el saludo ("Good evening, Alejandro").
  static const TextStyle greetingTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: PaseoColors.textWhite,
    height: 1.15,
  );

  /// Saldo de puntos numérico gigante en la tarjeta VIP ("3,450").
  static const TextStyle balanceHero = TextStyle(
    fontFamily: 'serif',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: Color(0xFFF0DEB4),
  );

  /// Título serif display grande para el nombre del miembro VIP.
  static const TextStyle memberName = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: PaseoColors.textWhite,
  );

  /// Título de pantalla en la barra superior ("Activity", "Profile").
  static const TextStyle screenTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: PaseoColors.textWhite,
  );

  /// Subtítulo pequeño sobre el logo ("PASEO POINTS").
  static const TextStyle brandLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: PaseoColors.goldMetallic,
  );

  /// Badge de membresía VIP ("VIP OBSIDIAN MEMBER • #ARJ-9921").
  static const TextStyle vipBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: PaseoColors.goldMetallic,
  );

  /// Título de tarjeta de acción ("Settings", "Help & Support").
  static const TextStyle actionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: PaseoColors.textWhite,
  );

  /// Subtítulo descriptivo de tarjeta ("Preferences & security").
  static const TextStyle actionSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: PaseoColors.textMuted,
  );

  /// Marca de agua inferior ("PASEO ARANJUEZ • PRIVATE LEDGER").
  static const TextStyle watermark = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: PaseoColors.goldDark,
  );

  /// Etiqueta de la barra de navegación ("CLUB", "REWARDS", etc.).
  static const TextStyle navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
}
