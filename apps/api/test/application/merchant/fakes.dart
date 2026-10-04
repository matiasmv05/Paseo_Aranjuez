/// Dobles de los puertos del panel del comercio (T045).
///
/// Sustituyen Postgres y HMAC; para la firma de tokens los tests usan el
/// `IdentificationSigner` real (ya probado) con un `FixedClock`, asi que el
/// TTL y la manipulacion se ejercitan de verdad.
library;

import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';

/// Reloj fijo para el TTL de tickets y el calculo de reglas.
final class FixedClock implements Clock {
  /// Crea el reloj con el instante [now].
  FixedClock(this.now);

  /// Instante devuelto por [nowUtc].
  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

/// Repositorio de contexto y clientes en memoria.
final class FakeEstablishmentRepository implements EstablishmentRepository {
  /// Crea el fake con el [context] de staff y los [customers] conocidos.
  FakeEstablishmentRepository({
    this.context,
    List<CustomerRecord> customers = const [],
  }) : _customers = customers;

  /// Contexto a devolver por [findContext] cuando el `userId` coincide.
  MerchantContext? context;

  final List<CustomerRecord> _customers;

  @override
  Future<MerchantContext?> findContext(String userId) async =>
      context?.userId == userId ? context : null;

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async {
    for (final customer in _customers) {
      if (customer.phone == phone) {
        return customer;
      }
    }
    return null;
  }

  @override
  Future<CustomerRecord?> findCustomerByUserId(String userId) async {
    for (final customer in _customers) {
      if (customer.userId == userId) {
        return customer;
      }
    }
    return null;
  }
}

/// Repositorio de reglas de conversion en memoria.
final class FakePointsRuleRepository implements PointsRuleRepository {
  /// Crea el fake con las [rules] candidatas.
  FakePointsRuleRepository(this.rules);

  /// Reglas devueltas por [findApplicableRules].
  List<PointsRule> rules;

  /// Ultimo `establishmentId` consultado.
  String? lastEstablishmentId;

  @override
  Future<List<PointsRule>> findApplicableRules({
    required String establishmentId,
    String? categoryId,
    required DateTime now,
  }) async {
    lastEstablishmentId = establishmentId;
    return rules;
  }
}

/// Repositorio de compras en memoria, con idempotencia y unicidad.
///
/// Es `base` (no `final`) para poder simular carreras de unicidad en los
/// tests heredando de el.
base class FakePurchaseRepository implements PurchaseRepository {
  /// Crea el fake; las compras insertadas usaran [createdAt].
  FakePurchaseRepository({DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.utc(2026, 10, 3, 12);

  /// Marca temporal de las compras insertadas.
  final DateTime createdAt;

  final Map<String, Purchase> _byKey = {};
  final Map<String, Purchase> _byInvoice = {};
  int _seq = 0;

  /// Si no es `null`, la siguiente insercion lanza esta violacion (carrera).
  PurchaseUniqueViolation? nextViolation;

  /// Compras insertadas, en orden.
  List<Purchase> get insertions => List.unmodifiable(_byKey.values);

  @override
  Future<Purchase?> findByIdempotencyKey({
    required String establishmentId,
    required String idempotencyKey,
  }) async => _byKey['$establishmentId|$idempotencyKey'];

  @override
  Future<Purchase?> findByInvoiceRef({
    required String establishmentId,
    required String invoiceRef,
  }) async => _byInvoice['$establishmentId|$invoiceRef'];

  @override
  Future<Purchase> insert(PurchaseDraft draft) async {
    final violation = nextViolation;
    if (violation != null) {
      nextViolation = null;
      throw violation;
    }
    final purchase = Purchase(
      id: 'p-${++_seq}',
      establishmentId: draft.establishmentId,
      branchId: draft.branchId,
      customerId: draft.customerId,
      sellerUserId: draft.sellerUserId,
      grossCents: draft.grossCents,
      discountCents: draft.discountCents,
      netCents: draft.netCents,
      invoiceRef: draft.invoiceRef,
      ruleId: draft.ruleId,
      campaignRuleId: draft.campaignRuleId,
      ruleSnapshot: draft.ruleSnapshot,
      idempotencyKey: draft.idempotencyKey,
      pointsCredited: draft.pointsCredited,
      createdAt: createdAt,
    );
    _byKey['${draft.establishmentId}|${draft.idempotencyKey}'] = purchase;
    _byInvoice['${draft.establishmentId}|${draft.invoiceRef}'] = purchase;
    return purchase;
  }
}

/// Construye una regla de conversion con valores de prueba sensatos.
PointsRule pointsRule({
  String id = 'base-1',
  PointsRuleScope scope = PointsRuleScope.establishment,
  PointsRuleType type = PointsRuleType.base,
  int priority = 0,
  int pointsAwarded = 10,
  int amountPerTierCents = 10000,
  int multiplierBp = 0,
  int? maxPointsPerPurchase,
  int minPurchaseCents = 0,
  Rounding rounding = Rounding.floor,
  DateTime? validFrom,
  DateTime? validTo,
  String? establishmentId = 'est-1',
  String? categoryId,
}) => PointsRule(
  id: id,
  scope: scope,
  type: type,
  priority: priority,
  pointsAwarded: pointsAwarded,
  amountPerTierCents: amountPerTierCents,
  multiplierBp: multiplierBp,
  maxPointsPerPurchase: maxPointsPerPurchase,
  minPurchaseCents: minPurchaseCents,
  rounding: rounding,
  validFrom: validFrom ?? DateTime.utc(2020),
  validTo: validTo,
  establishmentId: establishmentId,
  categoryId: categoryId,
);

/// Repositorio de movimientos que devuelve una pagina fija.
final class FakeMovementRepository implements MovementRepository {
  /// Crea el fake con la [page] a devolver.
  FakeMovementRepository(this.page);

  /// Pagina devuelta por [list].
  MovementPageData page;

  /// Ultima consulta recibida.
  MovementQuery? lastQuery;

  @override
  Future<MovementPageData> list(MovementQuery query) async {
    lastQuery = query;
    return page;
  }
}
