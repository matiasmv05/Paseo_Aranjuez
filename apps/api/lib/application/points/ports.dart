/// Puertos y modelos de lectura/escritura del módulo de puntos (feature 002).
///
/// La fuente de verdad del estado es `points_ledger` (solo inserción); el
/// saldo (`customer_balances`) lo deriva un trigger `SECURITY DEFINER`
/// (AGENTS.md §2 reglas 2-3, §9). Ningún caso de uso fuera de este módulo
/// importa estos repositorios (contrato interno para 003/005).
///
/// Los puertos de infraestructura genérica (`AuditLogWriter`,
/// `TransactionRunner`, `Clock`, `IdGenerator`) se reutilizan desde
/// `application/identity/ports.dart`; aquí solo se declaran los puertos
/// específicos de puntos.
library;

import 'package:paseo_api/domain/points/points.dart';

// ---------------------------------------------------------------------------
// Modelos de escritura (comandos ya viven en `domain/points`).
// ---------------------------------------------------------------------------

/// Entrada de una compra que el motor de crédito persiste junto al `CREDIT`
/// (soporte del ledger; el endpoint `POST /merchant/purchases` es de 003).
/// Dinero en centavos enteros (regla 2.9).
final class PurchaseInput {
  const new({
    required this.establishmentId,
    required this.customerId,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.idempotencyKey,
    this.branchId,
    this.invoiceRef,
  });

  final String establishmentId;
  final String? branchId;
  final String customerId;
  final int grossCents;
  final int discountCents;
  final int netCents;
  final String? invoiceRef;
  final String idempotencyKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseInput &&
          establishmentId == other.establishmentId &&
          branchId == other.branchId &&
          customerId == other.customerId &&
          grossCents == other.grossCents &&
          discountCents == other.discountCents &&
          netCents == other.netCents &&
          invoiceRef == other.invoiceRef &&
          idempotencyKey == other.idempotencyKey;

  @override
  int get hashCode => Object.hash(
    establishmentId,
    branchId,
    customerId,
    grossCents,
    discountCents,
    netCents,
    invoiceRef,
    idempotencyKey,
  );

  @override
  String toString() =>
      'PurchaseInput(establishmentId: $establishmentId, customerId: '
      '$customerId, netCents: $netCents, idempotencyKey: $idempotencyKey)';
}

/// Resultado de insertar un movimiento en el ledger: el `id` y el saldo
/// resultante (`balance_after`) que el trigger `SECURITY DEFINER` rellena
/// en la propia fila durante el `INSERT` (spec C3; AGENTS.md §2 regla 3).
/// El `occurredAt` lo fija el servidor (spec C2).
final class LedgerInsertResult {
  const new({
    required this.id,
    required this.balanceAfter,
    required this.occurredAt,
  });

  final String id;
  final int balanceAfter;
  final DateTime occurredAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerInsertResult &&
          id == other.id &&
          balanceAfter == other.balanceAfter &&
          occurredAt == other.occurredAt;

  @override
  int get hashCode => Object.hash(id, balanceAfter, occurredAt);
}

/// Resultado de un crédito: `ledgerId` del `CREDIT` y saldo resultante.
/// `replayed=true` indica que se devolvió la respuesta original de una
/// `Idempotency-Key` repetida (FR-006; spec C5).
final class CreditResult {
  const new({
    required this.ledgerId,
    required this.balanceAfter,
    required this.replayed,
  });

  final String ledgerId;
  final int balanceAfter;
  final bool replayed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditResult &&
          ledgerId == other.ledgerId &&
          balanceAfter == other.balanceAfter &&
          replayed == other.replayed;

  @override
  int get hashCode => Object.hash(ledgerId, balanceAfter, replayed);
}

/// Resultado de un débito: `ledgerId` del `REDEEM` y saldo resultante.
final class DebitResult {
  const new({
    required this.ledgerId,
    required this.balanceAfter,
    required this.replayed,
  });

  final String ledgerId;
  final int balanceAfter;
  final bool replayed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebitResult &&
          ledgerId == other.ledgerId &&
          balanceAfter == other.balanceAfter &&
          replayed == other.replayed;

  @override
  int get hashCode => Object.hash(ledgerId, balanceAfter, replayed);
}

/// Resultado de la reserva de idempotencia: lee la entrada existente para
/// `(scope, key)`. Si `foundExisting=false` el caso de uso procede a
/// ejecutar y luego [PointsIdempotencyRepository.confirm]; si `true`,
/// el caso de uso compara [storedRequestHash] para decidir replay
/// (mismo hash) o conflicto (hash distinto, spec C5).
final class IdempotencyReserveResult {
  const new({
    required this.foundExisting,
    this.storedRequestHash,
    this.storedLedgerId,
    this.storedResponse,
  });

  final bool foundExisting;
  final String? storedRequestHash;
  final String? storedLedgerId;
  final Map<String, Object?>? storedResponse;
}

// ---------------------------------------------------------------------------
// Modelos de lectura (devueltos por los repos de consulta; T011).
// ---------------------------------------------------------------------------

/// Movimiento del historial (HU-05). `origin` y `referenceId` se derivan
/// en la consulta (compra → `purchase_id`, canje → referencia de canje,
/// reversión → `reverses_ledger_id`); el ledger no tiene columna de
/// referencia (V005). Puntos enteros con signo.
final class LedgerMovement {
  const new({
    required this.id,
    required this.type,
    required this.deltaPoints,
    required this.occurredAt,
    required this.origin,
    required this.referenceId,
    required this.balanceAfter,
  });

  final String id;
  final MovementType type;
  final int deltaPoints;
  final DateTime occurredAt;

  /// purchase | redemption | adjustment | reversal (contrato `Movement`).
  final String origin;
  final String referenceId;
  final int balanceAfter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerMovement &&
          id == other.id &&
          type == other.type &&
          deltaPoints == other.deltaPoints &&
          occurredAt == other.occurredAt &&
          origin == other.origin &&
          referenceId == other.referenceId &&
          balanceAfter == other.balanceAfter;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    deltaPoints,
    occurredAt,
    origin,
    referenceId,
    balanceAfter,
  );
}

/// Página de movimientos con cursor opaco `(occurred_at, ledger_id)`
/// (FR-002; spec C7). `nextCursor` es `null` cuando no hay más páginas.
final class MovementsPage {
  const new({required this.items, this.nextCursor});

  final List<LedgerMovement> items;
  final String? nextCursor;
}

/// Saldo del cliente leído de `customer_balances` (HU-04). `null` cuando
/// el cliente no tiene movimientos (el caso de uso devuelve `0`).
final class BalanceView {
  const new({required this.balance, required this.updatedAt});

  final int balance;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceView &&
          balance == other.balance &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(balance, updatedAt);
}

/// Recompensa del catálogo (HU-06). Vista de cliente: sin campos
/// administrativos (`approved_by`, `compliance`, etc.). `available=false`
/// cuando `stock=0` (decisión 2026-10-03; spec C de aclaración).
final class RewardRecord {
  const new({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardType,
    required this.costPoints,
    required this.available,
    required this.establishmentId,
    this.stock,
    this.validFrom,
    this.validTo,
  });

  final String id;
  final String name;
  final String description;

  /// PERCENT | FIXED | GIFT (contrato `RewardSummary`).
  final String rewardType;
  final int costPoints;

  /// `null` = sin límite.
  final int? stock;
  final bool available;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String establishmentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardRecord &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          rewardType == other.rewardType &&
          costPoints == other.costPoints &&
          stock == other.stock &&
          available == other.available &&
          validFrom == other.validFrom &&
          validTo == other.validTo &&
          establishmentId == other.establishmentId;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    rewardType,
    costPoints,
    stock,
    available,
    validFrom,
    validTo,
    establishmentId,
  );
}

/// Sucursal de un establecimiento (HU-09).
final class BranchRecord {
  const new({required this.id, required this.name, required this.address});

  final String id;
  final String name;
  final String address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchRecord &&
          id == other.id &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => Object.hash(id, name, address);
}

/// Establecimiento participante (HU-09). Vista de cliente: sin
/// `max_purchase_cents` ni `compliance_status`.
final class EstablishmentRecord {
  const new({
    required this.id,
    required this.name,
    required this.category,
    required this.branches,
  });

  final String id;
  final String name;
  final String category;
  final List<BranchRecord> branches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstablishmentRecord &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          _listEquals(branches, other.branches);

  @override
  int get hashCode => Object.hash(id, name, category, Object.hashAll(branches));

  static bool _listEquals(List<BranchRecord> a, List<BranchRecord> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Puertos de persistencia (adaptadores en `adapters/out/postgres`).
// ---------------------------------------------------------------------------

/// Único punto de escritura de puntos (AGENTS.md §2 regla 2). El saldo lo
/// mantiene el trigger; el rol `paseo_app` no tiene `UPDATE/DELETE` sobre
/// el ledger (V005). `balance_after` lo rellena el trigger (spec C3).
abstract interface class PointsLedgerRepository {
  /// Inserta un `CREDIT` (delta positivo). El `reference` es la referencia
  /// externa (FR-005); la persistencia concreta la resuelve el adaptador.
  Future<LedgerInsertResult> insertCredit({
    required String customerId,
    required int points,
    required String reference,
    required DateTime occurredAt,
    String? purchaseId,
    String? idempotencyKey,
  });

  /// Inserta un `REDEEM` (delta negativo). Un `23514` del `CHECK (balance
  /// >= 0)` lo mapea el adaptador a [PointsException.insufficientPoints]
  /// (AGENTS.md §9; errors.dart: el mapeo vive en el adaptador, no aquí).
  Future<LedgerInsertResult> insertDebit({
    required String customerId,
    required int points,
    required String reference,
    required DateTime occurredAt,
    String? idempotencyKey,
  });
}

/// Reserva/replay de idempotencia del motor (FR-006; spec C5). Clave
/// `(scope, key)` única; mismo key + mismo payload → replay de la
/// respuesta original; mismo key + payload distinto → 409 `CONFLICT`.
abstract interface class PointsIdempotencyRepository {
  /// Lee la entrada existente para `(scope, key)`. No inserta: la inserción
  /// completa (con `response` NOT NULL en base) la hace [confirm] dentro
  /// de la transacción del motor, tras insertar el ledger.
  Future<IdempotencyReserveResult> reserveOrReplay({
    required String scope,
    required String key,
    required String requestHash,
  });

  /// Inserta la entrada idempotente completa (`request_hash`, `response`,
  /// `ledger_id`). El `requestHash` es necesario porque la columna
  /// `request_hash` es NOT NULL en `points_idempotency` (V005).
  Future<void> confirm({
    required String scope,
    required String key,
    required String requestHash,
    required String ledgerId,
    required Map<String, Object?> response,
  });
}

/// Persistencia de `purchases` (soporte del `CREDIT`; 003 posee el
/// endpoint). El `id` lo genera la base (`gen_random_uuid()`).
abstract interface class PurchaseRepository {
  Future<String> insert(PurchaseInput input);
}

/// Lectura de saldo (HU-04). `null` si el cliente no tiene fila en
/// `customer_balances` (saldo 0 sin crear fila vacía, FR-001).
abstract interface class BalanceRepository {
  Future<BalanceView?> findByCustomerId(String customerId);
}

/// Lectura del historial (HU-05), paginada por cursor `(occurred_at,
/// ledger_id)` (FR-002; spec C7).
abstract interface class MovementsRepository {
  Future<MovementsPage> getPage({
    required String customerId,
    String? cursor,
    int limit = 20,
  });
}

/// Catálogo de recompensas (HU-06): solo `ACTIVE` vigentes (spec C de
/// aclaración; las sin stock se incluyen con `available=false`).
abstract interface class RewardsRepository {
  Future<List<RewardRecord>> listActive({required DateTime now});
}

/// Establecimientos participantes (HU-09): solo activos, sin baja lógica.
abstract interface class EstablishmentsRepository {
  Future<List<EstablishmentRecord>> listActive();
}
