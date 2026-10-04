import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/qr_page.dart';
import 'package:paseo_mobile/pages/welcome_page.dart';

/// Pantalla 10: Perfil personal del cliente y ajustes de cuenta.
class ProfilePage extends StatelessWidget {
  /// Crea la pantalla de perfil.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // 1. Título de cabecera
          const Center(
            child: Text(
              'Mi perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PaseoColors.textDarkPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Avatar con badge de edición
          Center(
            child: Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PaseoColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      user.avatarAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: PaseoColors.primaryNavy,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: PaseoColors.primaryNavy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Nombre y datos de contacto
          Center(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: PaseoColors.textDarkPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 14,
                color: PaseoColors.textDarkSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 12,
                  color: PaseoColors.textDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_iphone_rounded,
                size: 14,
                color: PaseoColors.textDarkSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.phone,
                style: const TextStyle(
                  fontSize: 12,
                  color: PaseoColors.textDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Tarjeta de acceso directo a Mi código QR
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute(builder: (_) => const QrPage()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PaseoColors.borderLight, width: 1.1),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    color: PaseoColors.textDarkPrimary,
                    size: 32,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi código QR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PaseoColors.textDarkPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ver código >',
                          style: TextStyle(
                            fontSize: 12,
                            color: PaseoColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: PaseoColors.textPlaceholder,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Sección: Mi cuenta
          const Text(
            'Mi cuenta',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PaseoColors.textDarkPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PaseoColors.borderLight, width: 1.1),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Editar perfil',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edición de perfil disponible en MVP.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: PaseoColors.borderLight),
                _buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacidad',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Términos de privacidad de Paseo Points.',
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: PaseoColors.borderLight),
                _buildMenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notificaciones',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ajustes de notificaciones.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: PaseoColors.borderLight),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  textColor: PaseoColors.pointsSpent,
                  iconColor: PaseoColors.pointsSpent,
                  showChevron: false,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil<void>(
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = PaseoColors.textDarkPrimary,
    Color iconColor = PaseoColors.textDarkSecondary,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: showChevron
            ? const Icon(
                Icons.chevron_right_rounded,
                color: PaseoColors.textPlaceholder,
                size: 20,
              )
            : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
