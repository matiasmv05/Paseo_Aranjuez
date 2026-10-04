import 'package:flutter/material.dart';

/// Escala de espaciados, bordes y dimensiones del sistema de diseño.
abstract final class PaseoSpacing {
  /// Espaciado mínimo (4px).
  static const double xs = 4;

  /// Espaciado pequeño (8px).
  static const double sm = 8;

  /// Espaciado medio estándar (16px).
  static const double md = 16;

  /// Espaciado amplio (24px).
  static const double lg = 24;

  /// Espaciado extra amplio (32px).
  static const double xl = 32;

  /// Espaciado mayor para separaciones de sección (48px).
  static const double xxl = 48;

  /// Radio pequeño (10px).
  static const double radiusSm = 10;

  /// Radio estándar de tarjetas (18px) - exactamente como en la imagen.
  static const double radiusCard = 18;

  /// Radio grande (24px).
  static const double radiusLg = 24;

  /// Radio circular total.
  static const double radiusFull = 999;

  /// Radio de avatar principal en perfil.
  static const double avatarProfileRadius = 56;

  /// Radio de avatar compacto en barra superior.
  static const double avatarMiniRadius = 18;

  /// Padding horizontal estándar de pantalla.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);

  /// Padding interno de tarjetas de acción.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 18,
  );
}
