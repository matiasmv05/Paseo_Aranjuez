import 'package:paseo_api/domain/points/points.dart';
import 'package:test/test.dart';

void main() {
  group('PointsCursor', () {
    final testDateTime = DateTime.utc(2026, 10, 3, 15, 30, 45);
    const testLedgerId = 'ledger-123-abc';

    test(
      'encode genera string base64 válido desde occurred_at y ledger_id',
      () {
        final cursor = PointsCursor.encode(
          occurredAt: testDateTime,
          ledgerId: testLedgerId,
        );

        expect(cursor, isA<String>());
        expect(cursor, isNotEmpty);
        // Debe ser base64 válido (sin espacios, caracteres válidos)
        expect(cursor, matches(RegExp(r'^[A-Za-z0-9+/]*={0,2}$')));
      },
    );

    test('decode restaura occurred_at y ledger_id correctamente', () {
      final originalCursor = PointsCursor.encode(
        occurredAt: testDateTime,
        ledgerId: testLedgerId,
      );

      final decoded = PointsCursor.decode(originalCursor);

      expect(decoded.occurredAt, equals(testDateTime));
      expect(decoded.ledgerId, equals(testLedgerId));
    });

    test('roundtrip encode -> decode mantiene datos originales', () {
      final testCases = [
        (DateTime.utc(2026, 1), 'simple-id'),
        (DateTime.utc(2026, 12, 31, 23, 59, 59, 999), 'complex-id-with-dashes'),
        (DateTime.utc(2000), ''),
        (
          DateTime.utc(9999),
          'very-long-ledger-id-with-many-characters-and-numbers-123456789',
        ),
      ];

      for (final (dateTime, ledgerId) in testCases) {
        final encoded = PointsCursor.encode(
          occurredAt: dateTime,
          ledgerId: ledgerId,
        );
        final decoded = PointsCursor.decode(encoded);

        expect(
          decoded.occurredAt,
          equals(dateTime),
          reason: 'Failed for dateTime: $dateTime',
        );
        expect(
          decoded.ledgerId,
          equals(ledgerId),
          reason: 'Failed for ledgerId: $ledgerId',
        );
      }
    });

    test('decode con string inválido lanza FormatException', () {
      expect(
        () => PointsCursor.decode('invalid-base64!'),
        throwsA(isA<FormatException>()),
      );

      expect(() => PointsCursor.decode(''), throwsA(isA<FormatException>()));

      expect(
        () => PointsCursor.decode('not-base64-at-all'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'decode con base64 válido pero estructura inválida lanza FormatException',
      () {
        // Base64 válido pero que no decodifica a la estructura esperada
        const validBase64ButWrongStructure =
            'aGVsbG8gd29ybGQ='; // "hello world"

        expect(
          () => PointsCursor.decode(validBase64ButWrongStructure),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('CursorData properties son accesibles', () {
      final cursorData = CursorData(
        occurredAt: testDateTime,
        ledgerId: testLedgerId,
      );

      expect(cursorData.occurredAt, equals(testDateTime));
      expect(cursorData.ledgerId, equals(testLedgerId));
    });

    test('CursorData equality basada en occurred_at y ledger_id', () {
      final cursor1 = CursorData(
        occurredAt: testDateTime,
        ledgerId: testLedgerId,
      );
      final cursor2 = CursorData(
        occurredAt: testDateTime,
        ledgerId: testLedgerId,
      );
      final cursor3 = CursorData(
        occurredAt: testDateTime.add(const Duration(seconds: 1)),
        ledgerId: testLedgerId,
      );
      final cursor4 = CursorData(
        occurredAt: testDateTime,
        ledgerId: 'different-id',
      );

      expect(cursor1, equals(cursor2));
      expect(cursor1.hashCode, equals(cursor2.hashCode));
      expect(cursor1, isNot(equals(cursor3)));
      expect(cursor1, isNot(equals(cursor4)));
    });

    test('casos límite con fechas extremas', () {
      final extremeCases = [
        DateTime.utc(1970, 1), // Unix epoch
        DateTime.utc(2038, 1, 19, 3, 14, 7), // End of 32-bit time
        DateTime.utc(9999, 12, 31, 23, 59, 59, 999), // Max DateTime
      ];

      for (final dateTime in extremeCases) {
        final encoded = PointsCursor.encode(
          occurredAt: dateTime,
          ledgerId: 'test-id',
        );
        final decoded = PointsCursor.decode(encoded);

        expect(
          decoded.occurredAt,
          equals(dateTime),
          reason: 'Failed for extreme date: $dateTime',
        );
      }
    });
  });
}
