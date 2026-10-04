import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/catalog/application/establishments_controller.dart';
import 'package:paseo_mobile/features/catalog/application/rewards_controller.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';
import 'package:paseo_mobile/features/catalog/presentation/establishments_screen.dart';
import 'package:paseo_mobile/features/catalog/presentation/rewards_screen.dart';

import '../../fakes.dart';

void main() {
  Widget host(Widget screen) => MaterialApp(home: Scaffold(body: screen));

  group('RewardsScreen (HU-06, T019)', () {
    late FakeCatalogApi api;
    late RewardsController controller;

    setUp(() {
      api = FakeCatalogApi();
      controller = RewardsController(api);
    });

    testWidgets('muestra beneficios, costo, tipo y disponibilidad', (
      tester,
    ) async {
      api.rewardsResult = [
        reward(stock: 3),
        reward(
          id: 'r-2',
          name: '10% en tu compra',
          type: RewardType.percent,
          cost: 200,
          stock: null,
        ),
        reward(
          id: 'r-3',
          name: 'Bs 20 de descuento',
          type: RewardType.fixed,
          cost: 250,
          stock: 0,
          available: false,
        ),
      ];

      await tester.pumpWidget(host(RewardsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Café gratis'), findsOneWidget);
      expect(find.text('150 puntos'), findsOneWidget);
      expect(find.text('Regalo'), findsOneWidget);
      expect(find.text('Quedan 3'), findsOneWidget);
      expect(find.text('10% en tu compra'), findsOneWidget);
      expect(find.text('Descuento %'), findsOneWidget);
      expect(find.text('Descuento fijo'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.textContaining('Válido hasta'), findsWidgets);
    });

    testWidgets('estado vacío', (tester) async {
      api.rewardsResult = const [];

      await tester.pumpWidget(host(RewardsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('No hay beneficios disponibles ahora.'), findsOneWidget);
    });

    testWidgets('error muestra mensaje y permite reintentar', (tester) async {
      api.rewardsError = const ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
      );

      await tester.pumpWidget(host(RewardsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.text('Tu sesión expiró. Vuelve a iniciar sesión.'),
        findsOneWidget,
      );

      api
        ..rewardsError = null
        ..rewardsResult = [reward()];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Café gratis'), findsOneWidget);
    });
  });

  group('EstablishmentsScreen (HU-09, T019)', () {
    late FakeCatalogApi api;
    late EstablishmentsController controller;

    setUp(() {
      api = FakeCatalogApi();
      controller = EstablishmentsController(api);
    });

    testWidgets('muestra comercios y expande sus sucursales', (tester) async {
      api.establishmentsResult = [
        establishment(),
        establishment(id: 'est-2', name: 'Farmacia Centro', category: 'Salud'),
      ];

      await tester.pumpWidget(
        host(EstablishmentsScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Café Plaza Murillo'), findsOneWidget);
      expect(find.text('Cafetería'), findsOneWidget);
      expect(find.text('Farmacia Centro'), findsOneWidget);

      await tester.tap(find.text('Café Plaza Murillo'));
      await tester.pumpAndSettle();

      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Calle Comercio 123'), findsOneWidget);
    });

    testWidgets('estado vacío', (tester) async {
      api.establishmentsResult = const [];

      await tester.pumpWidget(
        host(EstablishmentsScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay comercios adheridos.'), findsOneWidget);
    });

    testWidgets('error FORBIDDEN muestra mensaje y permite reintentar', (
      tester,
    ) async {
      api.establishmentsError = const ApiException(
        statusCode: 403,
        code: 'FORBIDDEN',
      );

      await tester.pumpWidget(
        host(EstablishmentsScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No tienes permiso para ver esta información.'),
        findsOneWidget,
      );

      api
        ..establishmentsError = null
        ..establishmentsResult = [establishment()];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Café Plaza Murillo'), findsOneWidget);
    });
  });
}
