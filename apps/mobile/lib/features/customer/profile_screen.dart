import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/di/injection.dart';
import '../identity/identity_state.dart';
import '../identity/registration_screen.dart';

/// Perfil del cliente autenticado: datos básicos, QR y cierre de sesión.
class ProfileScreen extends StatefulWidget {
  ProfileScreen({
    Key? key,
    this.phone = '+59170123456',
    IdentityNotifier? notifier,
    this.qrPayload,
  }) : notifier =
           notifier ??
           IdentityNotifier(
             InjectionContainer.authRepository,
             tokenStorage: InjectionContainer.tokenStorage,
           ),
       super(key: key);

  final String phone;
  final IdentityNotifier notifier;

  /// Ticket QR firmado. En producción proviene de `GET /api/v1/customers/me/qr`.
  final String? qrPayload;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _logout() async {
    await widget.notifier.signOut();
    if (!mounted) {
      return;
    }
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<Widget>(builder: (_) => RegistrationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.qrPayload ?? 'paseo-qr:${widget.phone}';
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.phone),
              const SizedBox(height: 16),
              QrImageView(
                key: const Key('customerQr'),
                data: payload,
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('logoutButton'),
                onPressed: _logout,
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
