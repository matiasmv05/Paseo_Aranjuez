import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/application/merchant/use_cases/list_movements.dart';
import 'package:paseo_api/application/merchant/use_cases/preview_purchase.dart';
import 'package:paseo_api/application/merchant/use_cases/register_purchase.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:postgres/postgres.dart';

import 'support.dart';

/// IDs fijos del seed dev (`infra/seed/R__seed_dev.sql`). `paseo_app` no
/// puede crear comercios/sucursales/staff/reglas (V004/V005 solo dan
/// lectura), asi que los tests de integracion reutilizan estas filas.
const demoEstablishmentId = 'e0000000-0000-0000-0000-000000000001';
const demoEstablishmentName = 'Comercio Demo';
const demoOwnerUserId = '11111111-1111-1111-1111-111111111111';
const demoCashierUserId = '22222222-2222-2222-2222-222222222222';
const demoCustomerUserId = '33333333-3333-3333-3333-333333333333';
const demoCustomerPhone = '+59170000001';
const demoGlobalRuleId = 'f0000000-0000-0000-0000-000000000001';

/// Secreto compartido por el emisor y el verificador en los tests.
const identificationTestSecret = 'it-identification-secret';

/// Cablea los adapters reales y los casos de uso merchant sobre [db].
final class MerchantHarness {
  /// Construye el harness con los repositorios Postgres reales.
  MerchantHarness(this.db)
    : establishments = PostgresEstablishmentRepository(db),
      rules = PostgresPointsRuleRepository(db),
      purchases = PostgresPurchaseRepository(db),
      movements = PostgresMovementRepository(db);

  final PgDatabase db;
  final PostgresEstablishmentRepository establishments;
  final PostgresPointsRuleRepository rules;
  final PostgresPurchaseRepository purchases;
  final PostgresMovementRepository movements;

  static const signer = IdentificationSigner(secret: identificationTestSecret);
  final Clock clock = const SystemClock();

  /// `IdentifyCustomer` con las reglas reales de la base.
  IdentifyCustomer identifyCustomer() => IdentifyCustomer(
    establishments: establishments,
    signer: signer,
    clock: clock,
  );

  /// `PreviewPurchase`; [rules] permite inyectar reglas de borde.
  PreviewPurchase previewPurchase({PointsRuleRepository? rules}) =>
      PreviewPurchase(
        signer: signer,
        rules: rules ?? this.rules,
        resolver: const RuleResolver(),
        calculator: const PointsCalculator(),
        clock: clock,
      );

  /// `RegisterPurchase`; [rules] permite inyectar reglas de borde.
  RegisterPurchase registerPurchase({PointsRuleRepository? rules}) =>
      RegisterPurchase(
        signer: signer,
        rules: rules ?? this.rules,
        resolver: const RuleResolver(),
        calculator: const PointsCalculator(),
        purchases: purchases,
        clock: clock,
      );

  /// `ListMovements` sobre los movimientos reales.
  ListMovements listMovements() => ListMovements(movements: movements);

  /// Contexto del personal tal como lo resuelve la base (FR-017).
  Future<MerchantContext> contextFor(String userId) async {
    final context = await establishments.findContext(userId);
    if (context == null) {
      throw StateError('sin contexto de comercio para $userId');
    }
    return context;
  }

  /// Firma un ticket de identificacion sin pasar por `IdentifyCustomer`.
  String ticketFor({
    required String customerId,
    String? branchId,
    String establishmentId = demoEstablishmentId,
  }) {
    final issuedAt = clock.nowUtc();
    return signer.signTicket(
      IdentificationTicketClaims(
        customerId: customerId,
        establishmentId: establishmentId,
        branchId: branchId,
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(IdentificationTicketClaims.ttl),
      ),
    );
  }

  /// Firma un token QR vigente para [customerId].
  String qrFor(String customerId) {
    final issuedAt = clock.nowUtc();
    return signer.signQr(
      QrTokenClaims(
        customerId: customerId,
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(QrTokenClaims.ttl),
      ),
    );
  }
}

/// `PointsRuleRepository` en memoria para reglas de borde que el seed no
/// cubre (sin regla aplicable, compra bajo la minima). El camino feliz usa
/// el repositorio Postgres real.
final class StubPointsRuleRepository implements PointsRuleRepository {
  /// Crea el stub con las [rules] que devolvera siempre.
  const StubPointsRuleRepository(this.rules);

  final List<PointsRule> rules;

  @override
  Future<List<PointsRule>> findApplicableRules({
    required String establishmentId,
    String? categoryId,
    required DateTime now,
  }) async => rules;
}

/// Cliente verificado creado por el test (a diferencia del sembrado).
final class CustomerFixture {
  /// Crea el fixture.
  const CustomerFixture({
    required this.userId,
    required this.phone,
    required this.fullName,
  });

  final String userId;
  final String phone;
  final String fullName;
}

/// Crea un usuario cliente + perfil con telefono verificado en la base dev.
Future<CustomerFixture> createVerifiedCustomer(
  PgDatabase db, {
  String fullName = 'Ana Torres Quispe',
}) async {
  final users = PostgresUserRepository(db);
  final customers = PostgresCustomerRepository(db);
  final userId = newId();
  final phone = uniquePhone();
  final user = await users.insertIfAbsent(
    id: userId,
    email: Email.parse(uniqueEmail()),
    passwordHash: r'$argon2id$it-placeholder',
    role: UserRole.customer,
  );
  if (user == null) {
    throw StateError('no se pudo crear el usuario cliente');
  }
  await customers.insertIfAbsent(
    CustomerProfile(userId: userId, phone: phone, fullName: fullName),
  );
  await customers.markPhoneVerified(userId: userId, at: DateTime.now().toUtc());
  return CustomerFixture(userId: userId, phone: phone, fullName: fullName);
}

/// Primera sucursal (la "Principal" automatica) del comercio sembrado.
Future<String> principalBranchId(
  PgDatabase db, {
  String establishmentId = demoEstablishmentId,
}) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT id::text AS id FROM app.branches '
      'WHERE establishment_id = @est::uuid ORDER BY created_at ASC LIMIT 1',
    ),
    parameters: <String, Object?>{'est': establishmentId},
  );
  if (result.isEmpty) {
    throw StateError('el comercio $establishmentId no tiene sucursales');
  }
  return result.first.toColumnMap()['id']! as String;
}

/// Saldo actual en `app.customer_balances`; `null` si no hay fila aun.
Future<int?> balanceOf(PgDatabase db, String customerId) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT balance FROM app.customer_balances WHERE customer_id = @id::uuid',
    ),
    parameters: <String, Object?>{'id': customerId},
  );
  return result.isEmpty ? null : result.first.toColumnMap()['balance']! as int;
}

/// Cantidad de movimientos `CREDIT` del ledger ligados a [purchaseId].
Future<int> creditCountForPurchase(PgDatabase db, String purchaseId) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT count(*) AS n FROM app.points_ledger '
      "WHERE purchase_id = @id::uuid AND type = 'CREDIT'",
    ),
    parameters: <String, Object?>{'id': purchaseId},
  );
  return result.first.toColumnMap()['n']! as int;
}

/// Cantidad de filas de `app.purchases` con esa clave de idempotencia.
Future<int> purchaseCountByKey(
  PgDatabase db,
  String establishmentId,
  String idempotencyKey,
) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT count(*) AS n FROM app.purchases '
      'WHERE establishment_id = @est::uuid AND idempotency_key = @key',
    ),
    parameters: <String, Object?>{
      'est': establishmentId,
      'key': idempotencyKey,
    },
  );
  return result.first.toColumnMap()['n']! as int;
}
