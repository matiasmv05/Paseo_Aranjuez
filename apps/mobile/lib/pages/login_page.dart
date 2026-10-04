import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_brand_crest.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_input_field.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_secondary_button.dart';
import 'package:paseo_mobile/design_system/templates/client_scaffold_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/client_shell_page.dart';
import 'package:paseo_mobile/pages/register_page.dart';

/// Pantalla 2: Iniciar sesión oficial de Paseo Points.
class LoginPage extends StatefulWidget {
  /// Crea la pantalla de inicio de sesión.
  const new({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'valentina@email.com');
  final _passwordController = TextEditingController(text: 'PaseoVIP2025!');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const ClientShellPage()),
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
              // Logo heráldico centrado
              const Center(child: PaseoBrandCrest(size: 48)),
              const SizedBox(height: 28),

              // Título y subtítulo
              const Center(
                child: Text(
                  'Iniciar sesión',
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
                  'Ingresa a tu cuenta para continuar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Campo de correo
              PaseoInputField(
                label: 'Correo electrónico',
                hintText: 'tucorreo@ejemplo.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo de contraseña con toggle de visibilidad
              PaseoInputField(
                label: 'Contraseña',
                hintText: 'Ingresa tu contraseña',
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

              // Fila: Recordar mi cuenta + ¿Olvidaste tu contraseña?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: PaseoColors.primaryNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() => _rememberMe = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recordar mi cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          color: PaseoColors.textDarkSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recuperación enviada al correo.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PaseoColors.textDarkPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón Iniciar sesión (Navy)
              PaseoPrimaryButton(
                label: 'Iniciar sesión',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 20),

              // Separador "o"
              const Row(
                children: [
                  Expanded(child: Divider(color: PaseoColors.borderLight)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o',
                      style: TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textPlaceholder,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: PaseoColors.borderLight)),
                ],
              ),
              const SizedBox(height: 20),

              // Botón Continuar con Google
              PaseoSecondaryButton(
                label: 'Continuar con Google',
                icon: const Icon(
                  Icons.g_mobiledata_rounded,
                  color: Color(0xFFEA4335),
                  size: 28,
                ),
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 28),

              // Enlace inferior a Registro
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿No tienes una cuenta? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Regístrate',
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
