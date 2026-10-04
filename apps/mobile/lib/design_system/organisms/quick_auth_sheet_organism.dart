import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_brand_crest.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_welcome_button.dart';
import 'package:paseo_mobile/design_system/molecules/role_preview_card.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de hoja inferior para inicio de sesión y navegación entre roles
/// del frontend.
///
/// Permite al usuario iniciar sesión de demostración o explorar las 3
/// experiencias del frontend (Cliente VIP, Boutique POS, Admin Ejecutivo)
/// sin conexión al backend.
class QuickAuthSheetOrganism extends StatefulWidget {
  /// Crea la hoja modal de autenticación rápida.
  const new({
    required this.onSelectCustomer,
    required this.onSelectMerchant,
    required this.onSelectAdmin,
    super.key,
  });

  /// Callback para entrar a la experiencia del Cliente VIP.
  final VoidCallback onSelectCustomer;

  /// Callback para entrar a la experiencia de Comercio (POS).
  final VoidCallback onSelectMerchant;

  /// Callback para entrar a la experiencia de Administrador.
  final VoidCallback onSelectAdmin;

  @override
  State<QuickAuthSheetOrganism> createState() => _QuickAuthSheetOrganismState();
}

class _QuickAuthSheetOrganismState extends State<QuickAuthSheetOrganism> {
  int _tabIndex = 0; // 0 = Explorar Vistas, 1 = Formulario de Acceso
  final _phoneController = TextEditingController(text: '+591 71234567');
  final _passwordController = TextEditingController(text: 'PaseoVIP2026!');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PaseoColors.obsidianDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33D4AF37), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaseoColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Cabecera del modal
              Row(
                children: [
                  const PaseoBrandCrest(size: 32, showWordmark: false),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acceso al Sistema',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: PaseoColors.textWhite,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Frontend UI • Paseo Points',
                          style: TextStyle(
                            fontSize: 12,
                            color: PaseoColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PaseoColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Selector de pestaña (Explorar vistas vs Iniciar sesión)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PaseoColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PaseoColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'Vistas del Frontend',
                        isSelected: _tabIndex == 0,
                        onTap: () => setState(() => _tabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'Iniciar Sesión',
                        isSelected: _tabIndex == 1,
                        onTap: () => setState(() => _tabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_tabIndex == 0) ...[
                // Lista de experiencias disponibles
                RolePreviewCard(
                  title: 'Cliente VIP',
                  subtitle: 'Club Pass, saldo de puntos, catálogo y QR.',
                  roleBadge: 'MÓVIL',
                  icon: Icons.star_border_rounded,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectCustomer();
                  },
                ),
                const SizedBox(height: 12),
                RolePreviewCard(
                  title: 'Boutique POS',
                  subtitle:
                      'Terminal de comercio, emisión y cálculo de puntos.',
                  roleBadge: 'COMERCIO',
                  icon: Icons.point_of_sale_rounded,
                  badgeColor: const Color(0xFFC5A059),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectMerchant();
                  },
                ),
                const SizedBox(height: 12),
                RolePreviewCard(
                  title: 'Admin Ejecutivo',
                  subtitle:
                      'Métricas de volumen, gráfica y auditoría de ledger.',
                  roleBadge: 'ADMIN',
                  icon: Icons.analytics_outlined,
                  badgeColor: const Color(0xFFE5C07B),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectAdmin();
                  },
                ),
              ] else ...[
                // Formulario visual simulado
                const Text(
                  'Número de teléfono (+591)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: PaseoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: PaseoColors.textWhite),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      color: PaseoColors.goldPrimary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: PaseoColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.surfaceBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.surfaceBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.goldPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: PaseoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: PaseoColors.textWhite),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: PaseoColors.goldPrimary,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: PaseoColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: PaseoColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.surfaceBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.surfaceBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PaseoColors.goldPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PaseoWelcomeButton(
                  label: 'Ingresar como Cliente VIP',
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSelectCustomer();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF262838) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? PaseoColors.textWhite : PaseoColors.textMuted,
          ),
        ),
      ),
    );
  }
}
