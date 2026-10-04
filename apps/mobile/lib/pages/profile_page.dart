import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/organisms/profile_actions_card.dart';
import 'package:paseo_mobile/design_system/organisms/profile_hero_section.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Página de perfil del cliente VIP (diseño exacto de la captura).
class ProfilePage extends StatelessWidget {
  /// Crea la vista de perfil para miembros de Paseo Points.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 120, // Espacio para la barra de navegación inferior
      ),
      child: Column(
        children: [
          // 1. Héroe con Avatar dorado, Nombre y Badge
          const ProfileHeroSection(
            name: 'Alejandro Morales',
            tierLabel: 'VIP OBSIDIAN MEMBER',
            memberCode: '#ARJ-9921',
          ),
          const SizedBox(height: 36),

          // 2. Tarjetas de acción interactivas y marca de agua
          ProfileActionsCard(
            onSettingsTap: () => _showSettingsSheet(context),
            onHelpTap: () => _showConciergeSheet(context),
            onLogoutTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PaseoColors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PaseoColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'PREFERENCIAS & SEGURIDAD',
                  style: PaseoTypography.brandLabel,
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  Icons.lock_outline_rounded,
                  'Autenticación Biométrica',
                  true,
                ),
                _buildSettingRow(
                  Icons.notifications_active_outlined,
                  'Alertas de Puntos y Canjes',
                  true,
                ),
                _buildSettingRow(
                  Icons.sms_outlined,
                  'Verificación SMS (+591)',
                  true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PaseoColors.goldMetallic),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: PaseoColors.textWhite,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: null,
            activeThumbColor: PaseoColors.goldLight,
            activeTrackColor: PaseoColors.goldDark,
          ),
        ],
      ),
    );
  }

  void _showConciergeSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PaseoColors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaseoColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.room_service_outlined,
                  size: 48,
                  color: PaseoColors.goldLight,
                ),
                const SizedBox(height: 14),
                const Text(
                  'LÍNEA PRIVADA DE CONSERJERÍA',
                  style: PaseoTypography.brandLabel,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Atención personalizada 24/7 para reservas '
                  'exclusivas y asistencia VIP en '
                  'comercios del Paseo Aranjuez.',
                  textAlign: TextAlign.center,
                  style: PaseoTypography.actionSubtitle,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaseoColors.goldMetallic,
                    foregroundColor: PaseoColors.obsidianBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded),
                  label: const Text(
                    'CONTACTAR MAYORDOMO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: PaseoColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: PaseoColors.surfaceBorder),
            ),
            title: const Text(
              'Cerrar Sesión Privada',
              style: TextStyle(
                fontFamily: 'serif',
                color: PaseoColors.textWhite,
                fontSize: 20,
              ),
            ),
            content: const Text(
              '¿Deseas finalizar tu sesión en este dispositivo? '
              'Tus puntos del ledger privado permanecen resguardados.',
              style: PaseoTypography.actionSubtitle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: PaseoColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaseoColors.surfaceIcon,
                  foregroundColor: const Color(0xFFFF8A80),
                ),
                child: const Text('FINALIZAR SESIÓN'),
              ),
            ],
          );
        },
      ),
    );
  }
}
