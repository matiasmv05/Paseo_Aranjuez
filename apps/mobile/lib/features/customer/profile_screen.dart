import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/di/injection.dart';
import '../identity/identity_state.dart';
import '../identity/registration_screen.dart';
import 'data/customer_repository.dart';

/// Perfil del cliente autenticado: datos básicos, QR firmado y logout.
class ProfileScreen extends StatefulWidget {
  ProfileScreen({
    Key? key,
    this.phone = '+59170123456',
    IdentityNotifier? notifier,
    CustomerRepository? customerRepository,
    this.qrPayload,
  }) : notifier =
           notifier ??
           IdentityNotifier(
             InjectionContainer.authRepository,
             tokenStorage: InjectionContainer.tokenStorage,
           ),
       customerRepository =
           customerRepository ?? InjectionContainer.customerRepository,
       super(key: key);

  final String phone;
  final IdentityNotifier notifier;
  final CustomerRepository customerRepository;

  /// Ticket QR ya resuelto (p. ej. en tests). Si es null, se consulta
  /// `GET /api/v1/customers/me/qr` vía [customerRepository].
  final String? qrPayload;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late String _payload;
  bool _loadingQr = true;

  @override
  void initState() {
    super.initState();
    final provided = widget.qrPayload;
    if (provided != null) {
      _payload = provided;
      _loadingQr = false;
    } else {
      _loadQrTicket();
    }
  }

  Future<void> _loadQrTicket() async {
    var payload = 'paseo-qr:${widget.phone}';
    try {
      final token = await widget.notifier.currentAccessToken();
      if (token != null && token.isNotEmpty) {
        payload = await widget.customerRepository.fetchQrTicket(token);
      }
    } on Object {
      // Sin red o token inválido: se deja el placeholder local.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _payload = payload;
      _loadingQr = false;
    });
  }

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
              if (_loadingQr)
                const CircularProgressIndicator()
              else
                QrImageView(
                  key: const Key('customerQr'),
                  data: _payload,
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
