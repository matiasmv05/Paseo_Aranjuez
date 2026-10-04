import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de barra superior de navegación y búsqueda del portal POS.
class PosHeaderBar extends StatelessWidget {
  /// Crea la barra superior del terminal de boutique.
  const new({super.key, this.onSearchChanged, this.onNotificationTap});

  /// Callback al buscar patron pass o ID.
  final ValueChanged<String>? onSearchChanged;

  /// Callback al pulsar la campana.
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1017),
        border: Border(bottom: BorderSide(color: Color(0xFF1E202B))),
      ),
      child: Row(
        children: [
          // 1. Breadcrumbs
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OPERATIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFF787B8A),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 11, color: Color(0xFF787B8A)),
                ),
              ),
              Text(
                'BOUTIQUE POS\nTERMINAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFFE5C07B),
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // 2. Buscador de cliente / ticket central
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF151722),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF262838)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 17, color: Color(0xFF787B8A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textWhite,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search patron pass, order ID, VIP code',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5B5D6D),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // 3. Chip de estatus del comercio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF171924),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2B2E40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFE5C07B)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BOUTIQUE VALLDEMOSSA • TERMINAL 01 • ONLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 4. Campana de notificaciones con badge
          IconButton(
            onPressed: onNotificationTap,
            tooltip: 'Notificaciones',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: Color(0xFFC7CBD8),
                ),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 5. Usuario: Elena Vance (Floor Director)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ELENA VANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: PaseoColors.textWhite,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'FLOOR DIRECTOR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Color(0xFF787B8A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PaseoColors.goldMetallic.withValues(alpha: 0.6),
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/elena_vance_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: PaseoColors.goldLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
