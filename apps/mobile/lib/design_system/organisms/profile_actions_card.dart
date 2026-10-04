import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_shield_watermark.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_action_tile.dart';

/// Organismo que agrupa las tarjetas de acción del perfil VIP.
///
/// Implementa animaciones escalonadas de entrada para cada tarjeta y
/// finaliza con la marca de agua del ledger privado.
class ProfileActionsCard extends StatefulWidget {
  /// Crea la lista de tarjetas de acción.
  const new({super.key, this.onSettingsTap, this.onHelpTap, this.onLogoutTap});

  /// Acción al pulsar Settings.
  final VoidCallback? onSettingsTap;

  /// Acción al pulsar Help & Support.
  final VoidCallback? onHelpTap;

  /// Acción al pulsar Log Out.
  final VoidCallback? onLogoutTap;

  @override
  State<ProfileActionsCard> createState() => _ProfileActionsCardState();
}

class _ProfileActionsCardState extends State<ProfileActionsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _tile1Slide;
  late final Animation<Offset> _tile2Slide;
  late final Animation<Offset> _tile3Slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _tile1Slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _tile2Slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _tile3Slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
          ),
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
    return FadeTransition(
      opacity: _fade,
      child: Column(
        children: [
          // 1. Settings
          SlideTransition(
            position: _tile1Slide,
            child: PaseoActionTile(
              icon: Icons.tune_rounded,
              title: 'Settings',
              subtitle: 'Preferences & security',
              onTap: widget.onSettingsTap,
            ),
          ),
          const SizedBox(height: 14),

          // 2. Help & Support
          SlideTransition(
            position: _tile2Slide,
            child: PaseoActionTile(
              icon: Icons.support_agent_rounded,
              title: 'Help & Support',
              subtitle: 'Private concierge line',
              onTap: widget.onHelpTap,
            ),
          ),
          const SizedBox(height: 14),

          // 3. Log Out
          SlideTransition(
            position: _tile3Slide,
            child: PaseoActionTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'End private session',
              onTap: widget.onLogoutTap,
            ),
          ),
          const SizedBox(height: 38),

          // Marca de agua inferior
          const PaseoShieldWatermark(),
        ],
      ),
    );
  }
}
