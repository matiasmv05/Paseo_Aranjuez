import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/admin_node_status_card.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Barra lateral de navegación ejecutiva para Paseo Points Admin (Organismo).
class AdminSidebar extends StatelessWidget {
  /// Crea la barra lateral ejecutiva con opciones de conciergerie y
  /// administración.
  const new({this.selectedIndex = 0, this.onItemSelected, super.key});

  /// Índice del elemento de navegación activo (0 = Dashboard).
  final int selectedIndex;

  /// Callback al seleccionar un elemento del menú.
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D13),
        border: Border(right: BorderSide(color: Color(0xFF1C1E2A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Marca / Logotipo Corporativo
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 28),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.goldLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASEO',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                      Text(
                        'POINTS CONCIERGE',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
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

          // 2. Elementos del menú principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _AdminSidebarNavTile(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isActive: selectedIndex == 0,
                  onTap: () => onItemSelected?.call(0),
                ),
                const SizedBox(height: 6),
                _AdminSidebarNavTile(
                  icon: Icons.storefront_outlined,
                  label: 'Stores',
                  isActive: selectedIndex == 1,
                  onTap: () => onItemSelected?.call(1),
                ),
                const SizedBox(height: 6),
                _AdminSidebarNavTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Users',
                  isActive: selectedIndex == 2,
                  onTap: () => onItemSelected?.call(2),
                ),
                const SizedBox(height: 6),
                _AdminSidebarNavTile(
                  icon: Icons.military_tech_outlined,
                  label: 'Rewards',
                  isActive: selectedIndex == 3,
                  onTap: () => onItemSelected?.call(3),
                ),
                const SizedBox(height: 6),
                _AdminSidebarNavTile(
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  isActive: selectedIndex == 4,
                  onTap: () => onItemSelected?.call(4),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 3. Tarjeta de nodo boutique en la base
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: AdminNodeStatusCard(),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebarNavTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B1D28) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF2C2F42) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: isActive
                    ? const Color(0xFFE5C07B)
                    : const Color(0xFF787B8A),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.6,
                    color: isActive
                        ? const Color(0xFFE5C07B)
                        : const Color(0xFF9EA2B3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
