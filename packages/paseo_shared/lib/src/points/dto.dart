/// DTOs de puntos alineados con `docs/openapi.yaml` (schemas `Balance` y
/// `Movement`).
///
/// Contrato en `snake_case`; campos Dart en camelCase. Sin lógica de
/// dominio: solo serialización.
library;

// Los DTOs son contenedores planos; los nombres ya se documentan en
// openapi.yaml y replicarlos campo a campo no aporta.
// ignore_for_file: public_member_api_docs

/// `Balance`: saldo actual del cliente (HU-04).
final class Balance {
  const new({required this.balancePoints, required this.updatedAt});

  factory fromJson(Map<String, Object?> json) => Balance(
    balancePoints: json['balance_points']! as int,
    updatedAt: DateTime.parse(json['updated_at']! as String),
  );

  final int balancePoints;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'balance_points': balancePoints,
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Balance &&
          balancePoints == other.balancePoints &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(balancePoints, updatedAt);
}

/// `Movement`: movimiento del historial de puntos (HU-05).
final class Movement {
  const new({
    required this.id,
    required this.type,
    required this.deltaPoints,
    required this.occurredAt,
    required this.origin,
    required this.referenceId,
    required this.balanceAfter,
  });

  factory fromJson(Map<String, Object?> json) => Movement(
    id: json['id']! as String,
    type: json['type']! as String,
    deltaPoints: json['delta_points']! as int,
    occurredAt: DateTime.parse(json['occurred_at']! as String),
    origin: json['origin']! as String,
    referenceId: json['reference_id']! as String,
    balanceAfter: json['balance_after']! as int,
  );

  final String id;

  /// CREDIT | REDEEM | ADJUST | BONUS | REVERSAL.
  final String type;
  final int deltaPoints;
  final DateTime occurredAt;

  /// purchase | redemption | adjustment | reversal.
  final String origin;
  final String referenceId;
  final int balanceAfter;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'delta_points': deltaPoints,
    'occurred_at': occurredAt.toIso8601String(),
    'origin': origin,
    'reference_id': referenceId,
    'balance_after': balanceAfter,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movement &&
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
