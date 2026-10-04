/// DTOs del monedero del cliente según el contrato `docs/openapi.yaml`
/// (`Balance`, `Movement`). Sin lógica de negocio (AGENTS.md §3).
library;

/// Tipo de movimiento del ledger de puntos (`Movement.type`).
enum MovementType {
  /// Acreditación (p. ej. por compra).
  credit,

  /// Canje de recompensa.
  redeem,

  /// Ajuste administrativo.
  adjust,

  /// Bono de campaña.
  bonus,

  /// Anulación (reembolso) de un movimiento previo.
  reversal;

  /// Parsea el valor del contrato (`CREDIT`, `REDEEM`, …).
  static MovementType parse(String value) => switch (value) {
    'CREDIT' => MovementType.credit,
    'REDEEM' => MovementType.redeem,
    'ADJUST' => MovementType.adjust,
    'BONUS' => MovementType.bonus,
    'REVERSAL' => MovementType.reversal,
    _ => throw FormatException('Movement.type desconocido', value),
  };
}

/// Origen funcional de un movimiento (`Movement.origin`).
enum MovementOrigin {
  /// Compra afiliada.
  purchase,

  /// Canje.
  redemption,

  /// Ajuste manual del administrador.
  adjustment,

  /// Reembolso aprobado.
  reversal;

  /// Parsea el valor del contrato (`purchase`, `redemption`, …).
  static MovementOrigin parse(String value) => switch (value) {
    'purchase' => MovementOrigin.purchase,
    'redemption' => MovementOrigin.redemption,
    'adjustment' => MovementOrigin.adjustment,
    'reversal' => MovementOrigin.reversal,
    _ => throw FormatException('Movement.origin desconocido', value),
  };
}

/// Saldo real del cliente, derivado del ledger en el servidor.
final class Balance {
  /// DTO simple.
  const new({required this.balancePoints, required this.updatedAt});

  /// Deserializa el contrato `Balance`.
  factory fromJson(Map<String, Object?> json) => Balance(
    balancePoints: json['balance_points']! as int,
    updatedAt: DateTime.parse(json['updated_at']! as String),
  );

  /// Saldo actual en puntos (entero, nunca negativo).
  final int balancePoints;

  /// Fecha ISO 8601 UTC del último movimiento (o de la consulta).
  final DateTime updatedAt;
}

/// Movimiento del `points_ledger` (historial del cliente).
final class Movement {
  /// DTO simple.
  const new({
    required this.id,
    required this.type,
    required this.deltaPoints,
    required this.occurredAt,
    required this.origin,
    required this.referenceId,
    required this.balanceAfter,
  });

  /// Deserializa el contrato `Movement`.
  factory fromJson(Map<String, Object?> json) => Movement(
    id: json['id']! as String,
    type: MovementType.parse(json['type']! as String),
    deltaPoints: json['delta_points']! as int,
    occurredAt: DateTime.parse(json['occurred_at']! as String),
    origin: MovementOrigin.parse(json['origin']! as String),
    referenceId: json['reference_id']! as String,
    balanceAfter: json['balance_after']! as int,
  );

  /// Id del movimiento (uuid).
  final String id;

  /// Tipo del movimiento.
  final MovementType type;

  /// Puntos con signo (positivo acredita, negativo descuenta).
  final int deltaPoints;

  /// Fecha ISO 8601 UTC fijada por el servidor.
  final DateTime occurredAt;

  /// Origen funcional (compra, canje, ajuste, reversión).
  final MovementOrigin origin;

  /// Referencia de la operación (compra, canje o movimiento revertido).
  final String referenceId;

  /// Saldo resultante tras el movimiento (calculado en el servidor).
  final int balanceAfter;
}

/// Página del historial (`CursorPage<Movement>` del contrato).
final class MovementsPage {
  /// DTO simple.
  const new({required this.items, this.nextCursor});

  /// Deserializa una página de movimientos.
  factory fromJson(Map<String, Object?> json) {
    final rawItems = json['items'] as List<Object?>? ?? const [];
    return MovementsPage(
      items: [
        for (final item in rawItems)
          Movement.fromJson(Map<String, Object?>.from(item! as Map)),
      ],
      nextCursor: json['next_cursor'] as String?,
    );
  }

  /// Movimientos de la página (cronológico inverso).
  final List<Movement> items;

  /// Cursor de la página siguiente; `null` cuando no hay más.
  final String? nextCursor;
}
