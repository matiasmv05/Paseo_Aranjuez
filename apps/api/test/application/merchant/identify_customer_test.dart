import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);
  const signer = IdentificationSigner(secret: 'test-secret');

  const owner = MerchantContext(
    establishmentId: 'est-1',
    establishmentName: 'Paseo',
    userId: 'u-owner',
    role: MerchantRole.owner,
  );
  const cashier = MerchantContext(
    establishmentId: 'est-1',
    establishmentName: 'Paseo',
    userId: 'u-cashier',
    role: MerchantRole.cashier,
    branchId: 'br-1',
    branchName: 'Principal',
  );

  const verified = CustomerRecord(
    userId: 'c-1',
    fullName: 'Juan Perez',
    phone: '+59170000001',
    phoneVerified: true,
  );
  const unverified = CustomerRecord(
    userId: 'c-2',
    fullName: 'Ana',
    phone: '+59170000002',
    phoneVerified: false,
  );

  IdentifyCustomer build() => IdentifyCustomer(
    establishments: FakeEstablishmentRepository(
      context: owner,
      customers: const [verified, unverified],
    ),
    signer: signer,
    clock: FixedClock(now),
  );

  group('IdentifyCustomer (HU-10, FR-003)', () {
    test('telefono verificado devuelve ticket y nombre enmascarado', () async {
      final result = await build()(
        context: owner,
        input: const IdentifyByPhone('+59170000001'),
      );

      expect(result.customerName, 'Juan P.');
      expect(result.expiresAt, now.add(IdentificationTicketClaims.ttl));
      final claims = signer.verifyTicket(result.ticket, now: now);
      expect(claims, isNotNull);
      expect(claims!.customerId, 'c-1');
      expect(claims.establishmentId, 'est-1');
      expect(claims.branchId, isNull);
    });

    test('el dueno no fija sucursal y el cajero si (FR-017)', () async {
      final repo = FakeEstablishmentRepository(
        context: cashier,
        customers: const [verified],
      );
      final useCase = IdentifyCustomer(
        establishments: repo,
        signer: signer,
        clock: FixedClock(now),
      );

      final result = await useCase(
        context: cashier,
        input: const IdentifyByPhone('+59170000001'),
      );
      final claims = signer.verifyTicket(result.ticket, now: now);
      expect(claims!.branchId, 'br-1');
    });

    test('telefono desconocido -> CUSTOMER_NOT_FOUND', () async {
      await expectLater(
        build()(context: owner, input: const IdentifyByPhone('+59170000009')),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.customerNotFound,
          ),
        ),
      );
    });

    test('telefono no boliviano -> PHONE_NOT_SUPPORTED', () async {
      await expectLater(
        build()(context: owner, input: const IdentifyByPhone('+541100000000')),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.phoneNotSupported,
          ),
        ),
      );
    });

    test('telefono mal formado -> VALIDATION_FAILED', () async {
      await expectLater(
        build()(context: owner, input: const IdentifyByPhone('+591123')),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('telefono sin verificar -> PHONE_NOT_VERIFIED', () async {
      await expectLater(
        build()(context: owner, input: const IdentifyByPhone('+59170000002')),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.phoneNotVerified,
          ),
        ),
      );
    });

    test('QR valido identifica por user_id (FR-006)', () async {
      final token = signer.signQr(
        QrTokenClaims(
          customerId: 'c-1',
          issuedAt: now,
          expiresAt: now.add(QrTokenClaims.ttl),
        ),
      );

      final result = await build()(context: owner, input: IdentifyByQr(token));
      expect(result.customerName, 'Juan P.');
      final claims = signer.verifyTicket(result.ticket, now: now);
      expect(claims!.customerId, 'c-1');
    });

    test('QR vencido -> INVALID_QR_TOKEN', () async {
      final token = signer.signQr(
        QrTokenClaims(customerId: 'c-1', issuedAt: now, expiresAt: now),
      );

      await expectLater(
        build()(context: owner, input: IdentifyByQr(token)),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.invalidQrToken,
          ),
        ),
      );
    });

    test('QR de un cliente inexistente -> CUSTOMER_NOT_FOUND', () async {
      final token = signer.signQr(
        QrTokenClaims(
          customerId: 'c-ghost',
          issuedAt: now,
          expiresAt: now.add(QrTokenClaims.ttl),
        ),
      );

      await expectLater(
        build()(context: owner, input: IdentifyByQr(token)),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.customerNotFound,
          ),
        ),
      );
    });

    test('QR manipulado -> INVALID_QR_TOKEN', () async {
      await expectLater(
        build()(context: owner, input: const IdentifyByQr('no.es.valido')),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.invalidQrToken,
          ),
        ),
      );
    });
  });
}
