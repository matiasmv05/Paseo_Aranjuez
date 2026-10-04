import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/domain/loyalty/identification.dart';
import 'package:test/test.dart';

void main() {
  const signer = IdentificationSigner(secret: 'identification-secret');
  final issuedAt = DateTime.fromMillisecondsSinceEpoch(
    1700000000000,
    isUtc: true,
  );

  IdentificationTicketClaims ticket({String? branchId = 'branch-1'}) =>
      IdentificationTicketClaims(
        customerId: 'customer-1',
        establishmentId: 'establishment-1',
        branchId: branchId,
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(IdentificationTicketClaims.ttl),
      );

  QrTokenClaims qr() => QrTokenClaims(
    customerId: 'customer-1',
    issuedAt: issuedAt,
    expiresAt: issuedAt.add(QrTokenClaims.ttl),
  );

  group('IdentificationSigner (HMAC-SHA256)', () {
    test('ticket round-trips with the same claims', () {
      final claims = ticket();
      final token = signer.signTicket(claims);

      final verified = signer.verifyTicket(
        token,
        now: issuedAt.add(const Duration(seconds: 1)),
      );
      expect(verified, isNotNull);
      expect(verified!.customerId, claims.customerId);
      expect(verified.establishmentId, claims.establishmentId);
      expect(verified.branchId, claims.branchId);
      expect(verified.issuedAt, claims.issuedAt);
      expect(verified.expiresAt, claims.expiresAt);
    });

    test('owner ticket round-trips with null branch', () {
      final token = signer.signTicket(ticket(branchId: null));
      final verified = signer.verifyTicket(token, now: issuedAt);
      expect(verified, isNotNull);
      expect(verified!.branchId, isNull);
    });

    test('qr round-trips with the same claims', () {
      final claims = qr();
      final token = signer.signQr(claims);

      final verified = signer.verifyQr(token, now: issuedAt);
      expect(verified, isNotNull);
      expect(verified!.customerId, claims.customerId);
      expect(verified.issuedAt, claims.issuedAt);
      expect(verified.expiresAt, claims.expiresAt);
    });

    test('signing is deterministic and the token is opaque', () {
      final token = signer.signTicket(ticket());
      expect(token, equals(signer.signTicket(ticket())));
      expect(token.startsWith('{'), isFalse);
      expect(token.contains('customer-1'), isFalse);
      expect(token.contains('establishment-1'), isFalse);
    });

    test('a tampered payload breaks the signature', () {
      final token = signer.signTicket(ticket());
      final parts = token.split('.');
      final forged = '${parts[0]}x.${parts[1]}';
      expect(signer.verifyTicket(forged, now: issuedAt), isNull);
    });

    test('a tampered signature is rejected', () {
      final token = signer.signTicket(ticket());
      final parts = token.split('.');
      final tamperedSignature =
          '${parts[1].substring(0, parts[1].length - 1)}A';
      expect(
        signer.verifyTicket('${parts[0]}.$tamperedSignature', now: issuedAt),
        isNull,
      );
    });

    test('a token signed with another secret is rejected', () {
      const other = IdentificationSigner(secret: 'other-secret');
      final token = other.signTicket(ticket());
      expect(signer.verifyTicket(token, now: issuedAt), isNull);
    });

    test('a token QR cannot pass as a ticket and vice versa', () {
      final qrToken = signer.signQr(qr());
      final ticketToken = signer.signTicket(ticket());
      expect(signer.verifyTicket(qrToken, now: issuedAt), isNull);
      expect(signer.verifyQr(ticketToken, now: issuedAt), isNull);
    });

    test('QR TTL is respected (60 s)', () {
      final token = signer.signQr(qr());
      expect(
        signer.verifyQr(token, now: issuedAt.add(const Duration(seconds: 59))),
        isNotNull,
      );
      expect(
        signer.verifyQr(token, now: issuedAt.add(const Duration(seconds: 60))),
        isNull,
      );
    });

    test('ticket TTL is respected (300 s)', () {
      final token = signer.signTicket(ticket());
      expect(
        signer.verifyTicket(
          token,
          now: issuedAt.add(const Duration(seconds: 299)),
        ),
        isNotNull,
      );
      expect(
        signer.verifyTicket(
          token,
          now: issuedAt.add(const Duration(seconds: 300)),
        ),
        isNull,
      );
    });

    test('malformed tokens are rejected without throwing', () {
      for (final token in ['', 'abc', 'a.', '.b', 'a.b.c', '!!!.???', 'x']) {
        expect(
          signer.verifyTicket(token, now: issuedAt),
          isNull,
          reason: token,
        );
        expect(signer.verifyQr(token, now: issuedAt), isNull, reason: token);
      }
    });
  });
}
