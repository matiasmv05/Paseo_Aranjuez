import 'package:flutter/material.dart';

import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/catalog/application/establishments_controller.dart';
import 'package:paseo_mobile/features/catalog/application/rewards_controller.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_api.dart';
import 'package:paseo_mobile/features/catalog/presentation/establishments_screen.dart';
import 'package:paseo_mobile/features/catalog/presentation/rewards_screen.dart';
import 'package:paseo_mobile/features/wallet/application/balance_controller.dart';
import 'package:paseo_mobile/features/wallet/application/movements_controller.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_api.dart';
import 'package:paseo_mobile/features/wallet/presentation/balance_screen.dart';
import 'package:paseo_mobile/features/wallet/presentation/movements_screen.dart';

/// Punto de entrada móvil del cliente (AGENTS.md §4).
///
/// Configuración de desarrollo:
/// `--dart-define=PASEO_API_BASE=http://localhost:8080/api/v1` (default) y
/// `--dart-define=PASEO_TOKEN=<access token>` hasta que exista el login
/// móvil de la feature 001.
void main() {
  final apiClient = ApiClient();
  final walletApi = HttpWalletApi(apiClient);
  final catalogApi = HttpCatalogApi(apiClient);
  runApp(
    CustomerApp(
      balanceController: BalanceController(walletApi),
      movementsController: MovementsController(walletApi),
      rewardsController: RewardsController(catalogApi),
      establishmentsController: EstablishmentsController(catalogApi),
    ),
  );
}

/// App móvil del cliente: saldo, historial, catálogo de beneficios y
/// comercios (feature 002). Solo UI y estado de carga: el servidor es la
/// fuente de verdad (regla 2.1).
class CustomerApp extends StatelessWidget {
  /// Recibe los controladores ya construidos (los tests inyectan falsos del
  /// mismo contrato).
  const new({
    required this.balanceController,
    required this.movementsController,
    required this.rewardsController,
    required this.establishmentsController,
    super.key,
  });

  /// Controlador del saldo (HU-04).
  final BalanceController balanceController;

  /// Controlador del historial (HU-05).
  final MovementsController movementsController;

  /// Controlador del catálogo de beneficios (HU-06).
  final RewardsController rewardsController;

  /// Controlador de los establecimientos (HU-09).
  final EstablishmentsController establishmentsController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Points',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: _CustomerHome(
        balanceController: balanceController,
        movementsController: movementsController,
        rewardsController: rewardsController,
        establishmentsController: establishmentsController,
      ),
    );
  }
}

class _CustomerHome extends StatefulWidget {
  const new({
    required this.balanceController,
    required this.movementsController,
    required this.rewardsController,
    required this.establishmentsController,
  });

  final BalanceController balanceController;
  final MovementsController movementsController;
  final RewardsController rewardsController;
  final EstablishmentsController establishmentsController;

  @override
  State<_CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<_CustomerHome> {
  static const _titles = ['Mis puntos', 'Historial', 'Beneficios', 'Comercios'];

  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: [
          BalanceScreen(controller: widget.balanceController),
          MovementsScreen(controller: widget.movementsController),
          RewardsScreen(controller: widget.rewardsController),
          EstablishmentsScreen(controller: widget.establishmentsController),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Saldo',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Beneficios',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront),
            label: 'Comercios',
          ),
        ],
      ),
    );
  }
}
