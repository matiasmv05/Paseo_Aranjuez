import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_mobile/features/merchant/presentation/movements_screen.dart';

Map<String, Object?> _movement(String id) => {
  'id': id,
  'created_at': '2026-10-03T12:00:00Z',
  'invoice_ref': 'F-$id',
  'gross_cents': 10000,
  'discount_cents': 0,
  'net_cents': 10000,
  'points_credited': 10,
  'customer_name': 'J*** P***',
  'branch_id': 'b1',
};

http.Response _json(Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('pide la siguiente pagina al llegar al final', (tester) async {
    final requested = <Uri>[];
    final firstPage = List.generate(30, (i) => _movement('m$i'));
    final client = MerchantApiClient(
      baseUrl: Uri.parse('http://test.local/api/v1/'),
      httpClient: MockClient((request) async {
        requested.add(request.url);
        final cursor = request.url.queryParameters['cursor'];
        if (cursor == null) {
          return _json({'items': firstPage, 'next_cursor': 'c1'});
        }
        return _json({
          'items': [_movement('m-last')],
          'next_cursor': null,
        });
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [merchantApiProvider.overrideWithValue(client)],
        child: const MaterialApp(home: Scaffold(body: MovementsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(requested, hasLength(1));
    expect(find.textContaining('F-m0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(requested, hasLength(2));
    expect(requested.last.queryParameters['cursor'], 'c1');
    expect(find.textContaining('F-m-last'), findsOneWidget);
  });
}
