import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:test/test.dart';

void main() {
  final issued = DateTime.utc(2025, 1, 1, 12);
  final ticketExpires = issued.add(IdentificationTicketClaims.ttl);
  final qrExpires = issued.add(QrTokenClaims.ttl);

  IdentificationTicketClaims ticket({String? branchId}) =>
      IdentificationTicketClaims(
        customerId: 'cust-1',
        establishmentId: 'est-1',
        branchId: branchId,
        issuedAt: issued,
        expiresAt: ticketExpires,
      );

  QrTokenClaims qr() => QrTokenClaims(
    customerId: 'cust-1',
    issuedAt: issued,
    expiresAt: qrExpires,
  );

  group('IdentificationTicketClaims (HU-10, FR-003)', () {
    test('TTL por defecto es 300 s', () {
      expect(IdentificationTicketClaims.ttl, const Duration(minutes: 5));
      expect(ticket().lifetime, const Duration(minutes: 5));
    });

    test('round-trip de dueño (sin sucursal)', () {
      final original = ticket();
      final json = original.toJson();
      expect(json['kind'], 'ticket');
      expect(json.containsKey('br'), isFalse);
      final restored = IdentificationTicketClaims.fromJson(json);
      expect(restored?.customerId, 'cust-1');
      expect(restored?.establishmentId, 'est-1');
      expect(restored?.branchId, isNull);
      expect(restored?.issuedAt, issued);
      expect(restored?.expiresAt, ticketExpires);
    });

    test('round-trip de cajero (con sucursal)', () {
      final restored = IdentificationTicketClaims.fromJson(
        ticket(branchId: 'br-9').toJson(),
      );
      expect(restored?.branchId, 'br-9');
    });

    test('rechaza version distinta de 1', () {
      final json = ticket().toJson()..['v'] = 2;
      expect(IdentificationTicketClaims.fromJson(json), isNull);
    });

    test('rechaza un sobre de QR', () {
      expect(IdentificationTicketClaims.fromJson(qr().toJson()), isNull);
    });

    test('rechaza customerId o establishmentId vacios', () {
      expect(
        IdentificationTicketClaims.fromJson(ticket().toJson()..['cid'] = ''),
        isNull,
      );
      expect(
        IdentificationTicketClaims.fromJson(ticket().toJson()..['est'] = ''),
        isNull,
      );
    });

    test('rechaza tiempos negativos o no enteros', () {
      expect(
        IdentificationTicketClaims.fromJson(ticket().toJson()..['iat'] = -1),
        isNull,
      );
      expect(
        IdentificationTicketClaims.fromJson(ticket().toJson()..['iat'] = 'x'),
        isNull,
      );
    });

    test('ignora el tipo de token desde el payload (el sobre manda)', () {
      final restored = IdentificationTicketClaims.fromJson(
        ticket().toJson()..['kind'] = 'qr',
      );
      expect(restored, isNull);
    });
  });

  group('QrTokenClaims (FR-006)', () {
    test('TTL por defecto es 60 s', () {
      expect(QrTokenClaims.ttl, const Duration(seconds: 60));
      expect(qr().lifetime, const Duration(seconds: 60));
    });

    test('round-trip', () {
      final json = qr().toJson();
      expect(json['kind'], 'qr');
      expect(json.containsKey('est'), isFalse);
      final restored = QrTokenClaims.fromJson(json);
      expect(restored?.customerId, 'cust-1');
      expect(restored?.expiresAt, qrExpires);
    });

    test('rechaza un sobre de ticket', () {
      expect(QrTokenClaims.fromJson(ticket().toJson()), isNull);
    });

    test('rechaza customerId vacio', () {
      expect(QrTokenClaims.fromJson(qr().toJson()..['cid'] = ''), isNull);
    });
  });

  group('IdentificationTokenKind', () {
    test('resuelve por wire y devuelve null si no conoce', () {
      expect(
        IdentificationTokenKind.fromWire('ticket'),
        IdentificationTokenKind.ticket,
      );
      expect(IdentificationTokenKind.fromWire('otro'), isNull);
    });
  });
}
