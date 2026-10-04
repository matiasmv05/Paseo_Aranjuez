import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';

/// Pantalla de acceso del personal del comercio (T103).
///
/// Usa el login existente (`/auth/login` con `X-Paseo-Client` web comercio)
/// y guarda el contexto del comercio en la sesion Riverpod.
class LoginScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla de login.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(merchantSessionProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Paseo Points - Comercio')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingreso de personal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => unawaited(_submit()),
                  decoration: const InputDecoration(labelText: 'Contrasena'),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.loading ? null : () => unawaited(_submit()),
                  child: state.loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingresar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
