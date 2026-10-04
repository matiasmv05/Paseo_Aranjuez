import 'package:flutter/material.dart';

/// Paleta cromática oficial de Paseo Points para clientes VIP Obsidian.
///
/// Combina tonalidades obsidian/carbón profundo con acentos en oro metálico,
/// ámbar y acabados premium.
abstract final class PaseoColors {
  /// Fondo más profundo de la aplicación (negro obsidiana).
  static const Color obsidianBlack = Color(0xFF090A0D);

  /// Fondo base oscuro para vistas y pantallas.
  static const Color obsidianDark = Color(0xFF0D0E12);

  /// Superficie de tarjetas y contenedores elevados.
  static const Color surfaceCard = Color(0xFF14151B);

  /// Superficie elevada para estados hover o interactivos.
  static const Color surfaceCardHover = Color(0xFF1A1B24);

  /// Superficie para iconos circulares y contenedores internos.
  static const Color surfaceIcon = Color(0xFF1F202A);

  /// Borde sutil para tarjetas y divisores oscuros.
  static const Color surfaceBorder = Color(0xFF262732);

  /// Borde dorado muy sutil para destacar tarjetas VIP.
  static const Color borderGold = Color(0x33D4AF37);

  /// Oro clásico de Paseo Points (tono principal de marca).
  static const Color goldPrimary = Color(0xFFD4AF37);

  /// Oro claro / champán para textos de alto contraste y destellos.
  static const Color goldLight = Color(0xFFF5E6B8);

  /// Oro metálico cálido para insignias y detalles de prestigio.
  static const Color goldMetallic = Color(0xFFC5A059);

  /// Oro oscuro para sombras y degradados sutiles.
  static const Color goldDark = Color(0xFF8C7133);

  /// Texto blanco brillante para títulos principales.
  static const Color textWhite = Color(0xFFF6F7FA);

  /// Texto gris tenue para subtítulos y descripciones.
  static const Color textMuted = Color(0xFF8E8F96);

  /// Texto gris oscuro para metadatos secundarios.
  static const Color textDark = Color(0xFF555660);

  /// Verde esmeralda para puntos acumulados y estados exitosos.
  static const Color emerald = Color(0xFF2E7D32);

  /// Rojo rubí para reversiones y advertencias del ledger.
  static const Color ruby = Color(0xFFC62828);

  /// Degradado vertical de fondo obsidiana de alta gama.
  static const LinearGradient obsidianGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF13141B), Color(0xFF0C0D11), Color(0xFF07080B)],
  );

  /// Degradado de halo áurico para el avatar VIP.
  static const RadialGradient goldHaloGradient = RadialGradient(
    colors: [Color(0x40D4AF37), Color(0x20C5A059), Color(0x00000000)],
    stops: [0.3, 0.7, 1.0],
  );

  /// Degradado metálico para tarjetas de membresía.
  static const LinearGradient metalCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2029), Color(0xFF14151B), Color(0xFF0C0D12)],
  );
}
