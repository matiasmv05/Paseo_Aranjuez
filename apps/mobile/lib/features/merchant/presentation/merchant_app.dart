import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/presentation/identify_screen.dart';
import 'package:paseo_mobile/features/merchant/presentation/login_screen.dart';
import 'package:paseo_mobile/features/merchant/presentation/movements_screen.dart';

/// Raiz de la app web del comercio (T107).
///
/// Decide entre login y panel segun la sesion Riverpod; el flujo es
/// login -> identificar -> registrar compra -> movimientos.
class MerchantApp extends ConsumerWidget {
  /// Crea la app del comercio.
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(merchantSessionProvider);
    return MaterialApp(
      title: 'Paseo Points - Comercio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: session.isAuthenticated
          ? const MerchantShell()
          : const LoginScreen(),
    );
  }
}

/// Panel autenticado: pestanas de identificar y movimientos.
class MerchantShell extends ConsumerStatefulWidget {
  /// Crea el panel del comercio.
  const MerchantShell({super.key});

  @override
  ConsumerState<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends ConsumerState<MerchantShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(merchantSessionProvider).identity;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paseo Points - Comercio'),
        actions: [
          if (identity != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(identity.isCashier ? 'Cajero' : 'Dueno'),
              ),
            ),
          IconButton(
            onPressed: ref.read(merchantSessionProvider.notifier).logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [IdentifyScreen(), MovementsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_search),
            label: 'Identificar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
        ],
      ),
    );
  }
}
