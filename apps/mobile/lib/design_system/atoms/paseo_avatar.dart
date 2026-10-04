import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de avatar de usuario con halo áurico VIP y estrella de distinción.
class PaseoAvatar extends StatelessWidget {
  /// Crea un avatar para miembros de Paseo Points.
  const new({
    super.key,
    this.radius = 56,
    this.imageUrl,
    this.assetPath,
    this.hasGlow = true,
    this.hasStarBadge = true,
    this.borderWidth = 2.0,
  });

  /// Radio del avatar en píxeles lógicos.
  final double radius;

  /// URL opcional de la imagen de perfil.
  final String? imageUrl;

  /// Ruta opcional a un asset local de imagen.
  final String? assetPath;

  /// Indica si debe mostrar el halo dorado resplandeciente exterior.
  final bool hasGlow;

  /// Indica si debe mostrar la insignia de estrella dorada en la esquina.
  final bool hasStarBadge;

  /// Grosor del anillo dorado que enmarca el avatar.
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final avatarSize = radius * 2;
    final haloPadding = hasGlow ? radius * 0.35 : 0.0;

    return SizedBox(
      width: avatarSize + (haloPadding * 2),
      height: avatarSize + (haloPadding * 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de resplandor áurico
          if (hasGlow)
            Container(
              width: avatarSize + (haloPadding * 2),
              height: avatarSize + (haloPadding * 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: PaseoColors.goldHaloGradient,
              ),
            ),

          // Anillo dorado exterior
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PaseoColors.goldMetallic,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: PaseoColors.goldPrimary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: assetPath != null && assetPath!.isNotEmpty
                  ? Image.asset(
                      assetPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackPortrait(),
                    )
                  : imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackPortrait(),
                    )
                  : _buildFallbackPortrait(),
            ),
          ),

          // Estrella dorada de distinción VIP en el borde inferior derecho
          if (hasStarBadge)
            Positioned(
              bottom: haloPadding + (radius * 0.12),
              right: haloPadding + (radius * 0.12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaseoColors.obsidianBlack,
                  border: Border.all(
                    color: PaseoColors.goldMetallic,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  size: 13,
                  color: PaseoColors.goldLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Retrato estilizado en degradado oscuro para fallback elegante.
  Widget _buildFallbackPortrait() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2D35), Color(0xFF181920), Color(0xFF0F1015)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: radius * 1.1,
          color: PaseoColors.goldLight.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
