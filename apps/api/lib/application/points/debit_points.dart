import 'package:paseo_api/application/identity/ports.dart'
    show AuditLogWriter, Clock, TransactionRunner;
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';

/// Caso de uso de débito de puntos (HUT-04, FR-005/FR-006/FR-008).
///
/// Contrato interno que 005 (canje) invocará: inserta un `REDEEM` (delta
/// negativo) en el ledger dentro de una transacción con confirmación de
/// idempotencia y `audit_log`. El trigger actualiza el saldo y rellena
/// `balance_after`; si `balance + delta < 0` el `CHECK (balance >= 0)`
/// aborta con `23514` y el adaptador lo mapea a
/// [PointsException.insufficientPoints] (AGENTS.md §9). El caso de uso lo
/// propaga (la transacción revierte completa: nada queda a medias).
///
/// En 002 no hay endpoint REST de débito (decisión 03/10/2026); este caso
/// de uso es el contrato para 005. El `occurredAt` lo fija el servidor
/// (spec C2).
final class DebitPoints {
  const new({
    required this._ledger,
    required PointsIdempotencyRepository idempotency,
    required this._audit,
    required this._tx,
    required this._clock,
  }) : _idempotency = idempotency;

  static const String scope = 'points.debit';

  final PointsLedgerRepository _ledger;
  final PointsIdempotencyRepository _idempotency;
  final AuditLogWriter _audit;
  final TransactionRunner _tx;
  final Clock _clock;

  /// Debita puntos a [customerId] (canje).
  ///
  /// - [phoneVerified]: `pv` verificado (SEC-002).
  /// - [idempotencyKey] / [requestHash]: idempotencia (FR-006; spec C5).
  ///
  /// Si el saldo es insuficiente, el repositorio lanza
  /// [PointsException.insufficientPoints] (mapeo `23514` en el adaptador)
  /// y este caso de uso lo propaga; la transacción revierte.
  Future<DebitResult> call({
    required String customerId,
    required DebitCommand command,
    required bool phoneVerified,
    required String idempotencyKey,
    required String requestHash,
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
      final ledger = await _ledger.insertDebit(
        customerId: customerId,
        points: command.points,
        reference: command.reference,
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
        action: 'points.debit',
        entityType: 'points_ledger',
        entityId: ledger.id,
        userId: customerId,
      );
      return ledger;
    });

    return DebitResult(
      ledgerId: inserted.id,
      balanceAfter: inserted.balanceAfter,
      replayed: false,
    );
  }

  DebitResult _replay(String? storedLedgerId, Map<String, Object?>? response) {
    final balanceAfter = (response?['balance_after'] as int?) ?? 0;
    return DebitResult(
      ledgerId: storedLedgerId ?? '',
      balanceAfter: balanceAfter,
      replayed: true,
    );
  }
}
