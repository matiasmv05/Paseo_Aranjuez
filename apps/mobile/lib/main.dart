import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'features/identity/identity_state.dart';
import 'features/identity/registration_screen.dart';

/// Punto de entrada móvil del cliente (AGENTS.md §4).
void main() {
  InjectionContainer.setupDependencies();
  final identityNotifier = IdentityNotifier(InjectionContainer.authRepository);
  runApp(RegistrationScreen(notifier: identityNotifier));
}
