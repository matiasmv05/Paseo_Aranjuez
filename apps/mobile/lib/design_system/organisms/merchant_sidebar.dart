import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/pos_sidebar_card.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de barra lateral de navegación para el portal de comercio POS.
class MerchantSidebar extends StatelessWidget {
  /// Crea la barra lateral del comercio.
  const new({
    super.key,
    this.selectedItem = 'STORE FRONT / QUICK ENTRY',
    this.onItemSelected,
  });

  /// Elemento activo seleccionado.
  final String selectedItem;

  /// Callback emitido al pulsar una opción de menú.
  final ValueChanged<String>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      color: const Color(0xFF0C0D13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logotipo corporativo de Paseo Points
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PaseoColors.goldMetallic.withValues(alpha: 0.6),
                    ),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF2E2F3B), Color(0xFF14151C)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.goldLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASEO POINTS',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                      Text(
                        'ARANJUEZ CONCIERGE',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Color(0xFF787B8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // 2. Título de sección de navegación
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'NAVIGATION',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFF5B5D6D),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Elementos de menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.grid_view_rounded,
                  label: 'DASHBOARD',
                ),
                const SizedBox(height: 4),

                // Categoría STORES con subelemento activo
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  label: 'STORES',
                  isCategory: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF221F17),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF5B4A1D)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE5C07B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'STORE FRONT / QUICK\nENTRY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              height: 1.2,
                              color: Color(0xFFE5C07B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                _buildMenuItem(
                  icon: Icons.people_outline_rounded,
                  label: 'USERS',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.military_tech_outlined,
                  label: 'REWARDS',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'SETTINGS',
                ),
              ],
            ),
          ),

          // 4. Tarjeta inferior de estado de canal NFC
          const Padding(padding: EdgeInsets.all(18), child: PosSidebarCard()),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    bool isCategory = false,
  }) {
    return InkWell(
      onTap: () => onItemSelected?.call(label),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8A8D9E)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF8A8D9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
