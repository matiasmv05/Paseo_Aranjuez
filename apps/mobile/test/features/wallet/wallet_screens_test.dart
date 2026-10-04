import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/wallet/application/balance_controller.dart';
import 'package:paseo_mobile/features/wallet/application/movements_controller.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';
import 'package:paseo_mobile/features/wallet/presentation/balance_screen.dart';
import 'package:paseo_mobile/features/wallet/presentation/movements_screen.dart';

import '../../fakes.dart';

void main() {
  Widget host(Widget screen) => MaterialApp(home: Scaffold(body: screen));

  group('BalanceScreen (HU-04, T019)', () {
    late FakeWalletApi api;
    late BalanceController controller;

    setUp(() {
      api = FakeWalletApi();
      controller = BalanceController(api);
    });

    testWidgets('muestra el saldo al cargar', (tester) async {
      api.balanceResult = Balance(
        balancePoints: 1250,
        updatedAt: DateTime.utc(2026, 10, 3, 12),
      );

      await tester.pumpWidget(host(BalanceScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Mis puntos'), findsOneWidget);
      expect(find.text('1.250 pts'), findsOneWidget);
      expect(find.textContaining('Actualizado:'), findsOneWidget);
      expect(api.balanceCalls, 1);
    });

    testWidgets('muestra spinner mientras carga', (tester) async {
      final gate = Completer<void>();
      api
        ..balanceGate = gate
        ..balanceResult = Balance(
          balancePoints: 0,
          updatedAt: DateTime.utc(2026, 10, 3, 12),
        );

      await tester.pumpWidget(host(BalanceScreen(controller: controller)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('0 pts'), findsOneWidget);
    });

    testWidgets(
      'error PHONE_NOT_VERIFIED muestra mensaje y permite reintentar',
      (tester) async {
        api.balanceError = const ApiException(
          statusCode: 403,
          code: 'PHONE_NOT_VERIFIED',
        );

        await tester.pumpWidget(host(BalanceScreen(controller: controller)));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Verifica tu número de teléfono para acumular y ver '
            'puntos.',
          ),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);

        api
          ..balanceError = null
          ..balanceResult = Balance(
            balancePoints: 200,
            updatedAt: DateTime.utc(2026, 10, 3, 12),
          );
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(find.text('200 pts'), findsOneWidget);
        expect(api.balanceCalls, 2);
      },
    );
  });

  group('MovementsScreen (HU-05, T019)', () {
    late FakeWalletApi api;
    late MovementsController controller;

    setUp(() {
      api = FakeWalletApi();
      controller = MovementsController(api);
    });

    testWidgets('estado vacío', (tester) async {
      api.movementPages.add(const MovementsPage(items: []));

      await tester.pumpWidget(host(MovementsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes movimientos.'), findsOneWidget);
    });

    testWidgets('muestra movimientos con signo y saldo resultante', (
      tester,
    ) async {
      api.movementPages.add(
        MovementsPage(
          items: [
            movement(delta: 100),
            movement(n: 2, type: MovementType.redeem, delta: -40, balance: 60),
            movement(n: 3, type: MovementType.reversal, delta: -60, balance: 0),
          ],
        ),
      );

      await tester.pumpWidget(host(MovementsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Compra'), findsOneWidget);
      expect(find.text('Canje'), findsOneWidget);
      expect(find.text('Anulación'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('-40'), findsOneWidget);
      expect(find.textContaining('Saldo: 60'), findsOneWidget);
      expect(find.text('Fin del historial'), findsOneWidget);
    });

    testWidgets('scroll infinito: pide la página siguiente al llegar abajo', (
      tester,
    ) async {
      api.movementPages.addAll([
        MovementsPage(
          items: [for (var i = 1; i <= 8; i++) movement(n: i, delta: 10)],
          nextCursor: 'cursor-2',
        ),
        MovementsPage(
          items: [
            movement(n: 9, type: MovementType.bonus, delta: 5, balance: 85),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 250,
              child: MovementsScreen(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.movementsCalls, 1);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(api.movementsCalls, 2);
      expect(controller.items, hasLength(9));
      expect(find.text('Bono'), findsOneWidget);
    });

    testWidgets('error de red muestra mensaje y permite reintentar', (
      tester,
    ) async {
      api.movementsError = const ApiException.network('sin DNS');

      await tester.pumpWidget(host(MovementsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
        findsOneWidget,
      );

      api
        ..movementsError = null
        ..movementPages.add(MovementsPage(items: [movement(delta: 100)]));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Compra'), findsOneWidget);
      expect(api.movementsCalls, 2);
    });
  });
}
