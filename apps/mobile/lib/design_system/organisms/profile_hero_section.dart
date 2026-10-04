import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_avatar.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_badge.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Organismo de cabecera principal del perfil de cliente VIP.
///
/// Presenta el avatar con halo áurico, el nombre del socio en tipografía serif
/// y la insignia de categoría con animaciones escalonadas de entrada.
class ProfileHeroSection extends StatefulWidget {
  /// Crea la sección de héroe de perfil.
  const new({
    required this.name,
    required this.tierLabel,
    required this.memberCode,
    super.key,
    this.avatarUrl,
  });

  /// Nombre completo del cliente (ej. "Alejandro Morales").
  final String name;

  /// Nivel de membresía (ej. "VIP OBSIDIAN MEMBER").
  final String tierLabel;

  /// Identificador exclusivo de cliente (ej. "#ARJ-9921").
  final String memberCode;

  /// URL de imagen de perfil opcional.
  final String? avatarUrl;

  @override
  State<ProfileHeroSection> createState() => _ProfileHeroSectionState();
}

class _ProfileHeroSectionState extends State<ProfileHeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _avatarScale;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _avatarScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
    );

    _nameFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );

    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _badgeFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar VIP con escala y halo
        ScaleTransition(
          scale: _avatarScale,
          child: PaseoAvatar(
            radius: 64,
            imageUrl: widget.avatarUrl,
            assetPath: 'assets/images/alejandro_avatar.jpg',
          ),
        ),
        const SizedBox(height: 18),

        // Nombre de socio con fade + slide
        FadeTransition(
          opacity: _nameFade,
          child: SlideTransition(
            position: _nameSlide,
            child: Text(
              widget.name,
              textAlign: TextAlign.center,
              style: PaseoTypography.memberName,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Badge de socio VIP Obsidian
        FadeTransition(
          opacity: _badgeFade,
          child: PaseoBadge(
            label: widget.tierLabel,
            memberCode: widget.memberCode,
          ),
        ),
      ],
    );
  }
}
