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

  /// Tono champán dorado cálido principal del botón Comenzar.
  static const Color champagneLight = Color(0xFFE8CA9D);

  /// Tono champán dorado profundo para el degradado del botón Comenzar.
  static const Color champagneDark = Color(0xFFC79E69);

  /// Color de texto oscuro de alto contraste sobre botón champán.
  static const Color champagneTextDark = Color(0xFF1E170F);

  /// Degradado cálido champán para botones principales de inicio.
  static const LinearGradient champagnePillGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8CA9D), Color(0xFFC79E69)],
  );

  /// Degradado superior oscuro para legibilidad sobre fondo arquitectónico.
  static const LinearGradient welcomeTopGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
    colors: [Color(0xF007080B), Color(0x9907080B), Color(0x00000000)],
  );

  /// Degradado inferior oscuro para el bloque de botones de bienvenida.
  static const LinearGradient welcomeBottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 1.0],
    colors: [Color(0x00000000), Color(0xB307080B), Color(0xFA07080B)],
  );

  // --- PALETA CLARA / ARQUITECTÓNICA (MOCKUP OFICIAL) ---

  /// Fondo principal claro marfil / off-white (#F8F8FA).
  static const Color bgLight = Color(0xFFF8F8FA);

  /// Superficie blanca pura para tarjetas e inputs (#FFFFFF).
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Borde sutil para tarjetas y campos (#EAE9E5).
  static const Color borderLight = Color(0xFFEBEAE6);

  /// Color primario oscuro institucional (#19202E).
  static const Color primaryNavy = Color(0xFF19202E);

  /// Superficie primaria con hover (#252F42).
  static const Color primaryNavyLight = Color(0xFF252F42);

  /// Texto oscuro principal (#1A1D24).
  static const Color textDarkPrimary = Color(0xFF1A1D24);

  /// Texto secundario (#6C7280).
  static const Color textDarkSecondary = Color(0xFF6C7280);

  /// Texto terciario / placeholder (#9C9FA8).
  static const Color textPlaceholder = Color(0xFF9C9FA8);

  /// Fondo de insignia de puntos dorada (#F9F3EA).
  static const Color goldBadgeBg = Color(0xFFF9F3EA);

  /// Borde sutil de insignia de puntos dorada (#ECD8B8).
  static const Color goldBadgeBorder = Color(0xFFECD8B8);

  /// Texto de insignia de puntos dorada (#8C6527).
  static const Color goldBadgeText = Color(0xFF8C6527);

  /// Fondo de chip inactivo (#F0EFEB).
  static const Color chipInactiveBg = Color(0xFFF0EFEB);

  /// Texto de chip inactivo (#5D6270).
  static const Color chipInactiveText = Color(0xFF5D6270);

  /// Verde de puntos ganados (#2E7D32).
  static const Color pointsEarned = Color(0xFF2E7D32);

  /// Fondo verde suave (#EAF5EA).
  static const Color pointsEarnedBg = Color(0xFFEAF5EA);

  /// Rojo de puntos canjeados (#D32F2F).
  static const Color pointsSpent = Color(0xFFD32F2F);

  /// Fondo rojo suave (#FDEAEA).
  static const Color pointsSpentBg = Color(0xFFFDEAEA);

  /// Fondo de aviso azul informativo (#EDF3F8).
  static const Color infoCalloutBg = Color(0xFFEDF3F8);

  /// Texto / icono de aviso azul (#2B6CB0).
  static const Color infoCalloutText = Color(0xFF2B6CB0);

  /// Fondo de aviso melocotón / teléfono (#FFF4ED).
  static const Color phoneCalloutBg = Color(0xFFFFF4ED);

  /// Texto / icono de aviso melocotón (#DD6B20).
  static const Color phoneCalloutText = Color(0xFFDD6B20);
}
