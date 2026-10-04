import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_brand_crest.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_input_field.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/templates/client_scaffold_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/client_shell_page.dart';

/// Pantalla de Registro de nuevo cliente para Paseo Points.
class RegisterPage extends StatefulWidget {
  /// Crea la pantalla de registro.
  const new({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController(text: 'Valentina Rodríguez');
  final _emailController = TextEditingController(text: 'valentina@email.com');
  final _phoneController = TextEditingController(text: '+591 720 12345');
  final _passwordController = TextEditingController(text: 'PaseoVIP2025!');
  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute(builder: (_) => const ClientShellPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClientScaffoldTemplate(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: PaseoColors.textDarkPrimary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: PaseoBrandCrest(size: 44)),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: PaseoColors.textDarkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Únete a Paseo Points y acumula beneficios',
                  style: TextStyle(
                    fontSize: 13,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PaseoInputField(
                label: 'Nombre completo',
                hintText: 'Ej. Valentina Rodríguez',
                controller: _nameController,
              ),
              const SizedBox(height: 14),
              PaseoInputField(
                label: 'Correo electrónico',
                hintText: 'tucorreo@ejemplo.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              PaseoInputField(
                label: 'Teléfono celular (+591)',
                hintText: '+591 700 00000',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              PaseoInputField(
                label: 'Contraseña',
                hintText: 'Crea una contraseña segura',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: PaseoColors.textPlaceholder,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _acceptTerms,
                      activeColor: PaseoColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() => _acceptTerms = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Acepto los Términos de Servicio y Privacidad.',
                      style: TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PaseoPrimaryButton(
                label: 'Registrarse',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textDarkPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
