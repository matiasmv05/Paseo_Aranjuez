import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_mobile/features/merchant/presentation/identify_screen.dart';
import 'package:paseo_mobile/features/merchant/presentation/purchase_screen.dart';

http.Response _json(Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('identifica (nombre enmascarado) y usa los puntos del servidor', (
    tester,
  ) async {
    final client = MerchantApiClient(
      baseUrl: Uri.parse('http://test.local/api/v1/'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/customers/identify')) {
          return _json({
            'ticket': 'ticket-1',
            'expires_at': '2026-10-03T12:05:00Z',
            'customer_name': 'J*** P***',
          });
        }
        if (path.endsWith('/purchases/preview')) {
          return _json({
            'points': 10,
            'rule_id': 'rule-1',
            'campaign_rule_id': null,
            'breakdown': {
              'points_base': 10,
              'multiplier_bp': 10000,
              'points_after_multiplier': 10,
              'points_before_cap': 10,
              'cap_applied': false,
              'below_min_purchase': false,
              'rounding': 'FLOOR',
            },
          });
        }
        return http.Response('{}', 404);
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [merchantApiProvider.overrideWithValue(client)],
        child: const MaterialApp(home: Scaffold(body: IdentifyScreen())),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '+59170000001');
    await tester.tap(find.text('Identificar'));
    await tester.pumpAndSettle();

    expect(find.text('J*** P***'), findsOneWidget);

    await tester.tap(find.text('Registrar compra'));
    await tester.pumpAndSettle();

    final purchaseFields = find.descendant(
      of: find.byType(PurchaseScreen),
      matching: find.byType(TextField),
    );
    expect(purchaseFields, findsNWidgets(4));

    await tester.enterText(purchaseFields.at(0), '10000');
    await tester.enterText(purchaseFields.at(3), 'F-1');
    await tester.tap(find.text('Previsualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Puntos a otorgar: 10'), findsOneWidget);
  });
}
