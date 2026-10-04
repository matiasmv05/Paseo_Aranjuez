import 'package:paseo_api/application/identity/ports.dart'
    show AuditLogWriter, Clock, TransactionRunner;
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';

/// Caso de uso de acreditación de puntos (HUT-04, FR-005/FR-006/FR-008).
///
/// Es el contrato interno que 003 (compras) invoca para acreditar puntos:
/// una transacción inserta la compra (si aplica) + el `CREDIT` en el
/// ledger + la confirmación de idempotencia + `audit_log`. El trigger
/// `SECURITY DEFINER` actualiza `customer_balances` y rellena
/// `balance_after` en la propia fila (spec C3); `CHECK (balance >= 0)`
/// no aplica al crédito (delta positivo). El `occurredAt` lo fija el
/// servidor (spec C2).
///
/// Reglas: `pv=false` → `PHONE_NOT_VERIFIED` (SEC-002). Misma
/// `Idempotency-Key` + mismo payload → respuesta original (replay); mismo
/// key + payload distinto → `CONFLICT` (spec C5). Sin PII en logs/errores.
final class CreditPoints {
  const new({
    required this._ledger,
    required PointsIdempotencyRepository idempotency,
    required this._purchases,
    required this._audit,
    required this._tx,
    required this._clock,
  }) : _idempotency = idempotency;

  static const String scope = 'points.credit';

  final PointsLedgerRepository _ledger;
  final PointsIdempotencyRepository _idempotency;
  final PurchaseRepository _purchases;
  final AuditLogWriter _audit;
  final TransactionRunner _tx;
  final Clock _clock;

  /// Acredita puntos a [customerId].
  ///
  /// - [phoneVerified]: `pv` verificado (SEC-002); lo aporta el invocador
  ///   (003) desde el JWT.
  /// - [purchaseInput]: compra de soporte; `null` si el crédito no viene
  ///   de una compra (p. ej. bonus futuro).
  /// - [idempotencyKey] / [requestHash]: clave y hash del payload para
  ///   idempotencia (FR-006; spec C5).
  Future<CreditResult> call({
    required String customerId,
    required CreditCommand command,
    required bool phoneVerified,
    required String idempotencyKey,
    required String requestHash,
    PurchaseInput? purchaseInput,
  }) async {
    if (!phoneVerified) {
      throw PointsException.phoneNotVerified();
    }

    final reserve = await _idempotency.reserveOrReplay(
      scope: scope,
      key: idempotencyKey,
      requestHash: requestHash,
    );
    if (reserve.foundExisting) {
      if (reserve.storedRequestHash != requestHash) {
        throw PointsException.conflict(
          'idempotency key reutilizada con payload distinto',
        );
      }
      return _replay(reserve.storedLedgerId, reserve.storedResponse);
    }

    final occurredAt = _clock.nowUtc();

    final inserted = await _tx.run(() async {
      String? purchaseId;
      if (purchaseInput != null) {
        purchaseId = await _purchases.insert(purchaseInput);
      }
      final ledger = await _ledger.insertCredit(
        customerId: customerId,
        points: command.points,
        reference: command.reference,
        purchaseId: purchaseId,
        occurredAt: occurredAt,
        idempotencyKey: idempotencyKey,
      );
      final response = <String, Object?>{
        'ledger_id': ledger.id,
        'balance_after': ledger.balanceAfter,
        'occurred_at': ledger.occurredAt.toIso8601String(),
      };
      await _idempotency.confirm(
        scope: scope,
        key: idempotencyKey,
        requestHash: requestHash,
        ledgerId: ledger.id,
        response: response,
      );
      await _audit.write(
        action: 'points.credit',
        entityType: 'points_ledger',
        entityId: ledger.id,
        userId: customerId,
      );
      return ledger;
    });

    return CreditResult(
      ledgerId: inserted.id,
      balanceAfter: inserted.balanceAfter,
      replayed: false,
    );
  }

  CreditResult _replay(String? storedLedgerId, Map<String, Object?>? response) {
    final balanceAfter = (response?['balance_after'] as int?) ?? 0;
    return CreditResult(
      ledgerId: storedLedgerId ?? '',
      balanceAfter: balanceAfter,
      replayed: true,
    );
  }
}
