/// DTOs del catálogo del cliente según el contrato `docs/openapi.yaml`
/// (`RewardSummary`, `EstablishmentSummary`, `BranchSummary`). Sin lógica de
/// negocio (AGENTS.md §3); los campos administrativos nunca llegan a la app
/// (regla 2.10: umbrales de fraude y cumplimiento no se exponen).
library;

/// Tipo de recompensa (`RewardSummary.reward_type`).
enum RewardType {
  /// Descuento porcentual.
  percent,

  /// Monto fijo de descuento.
  fixed,

  /// Regalo o canje en especie.
  gift;

  /// Parsea el valor del contrato (`PERCENT`, `FIXED`, `GIFT`).
  static RewardType parse(String value) => switch (value) {
    'PERCENT' => RewardType.percent,
    'FIXED' => RewardType.fixed,
    'GIFT' => RewardType.gift,
    _ => throw FormatException('RewardSummary.reward_type desconocido', value),
  };
}

/// Beneficio canjeable con puntos (`RewardSummary`).
final class RewardSummary {
  /// DTO simple.
  const new({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.costPoints,
    required this.stock,
    required this.available,
    required this.validFrom,
    required this.validTo,
    required this.establishmentId,
  });

  /// Deserializa el contrato `RewardSummary`.
  factory fromJson(Map<String, Object?> json) {
    final validFrom = json['valid_from'] as String?;
    final validTo = json['valid_to'] as String?;
    return RewardSummary(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      type: RewardType.parse(json['reward_type']! as String),
      costPoints: json['cost_points']! as int,
      stock: json['stock'] as int?,
      available: json['available']! as bool,
      validFrom: validFrom == null ? null : DateTime.parse(validFrom),
      validTo: validTo == null ? null : DateTime.parse(validTo),
      establishmentId: json['establishment_id']! as String,
    );
  }

  /// Id de la recompensa (uuid).
  final String id;

  /// Nombre visible.
  final String name;

  /// Descripción del beneficio.
  final String description;

  /// Tipo de recompensa.
  final RewardType type;

  /// Costo en puntos (entero; nunca `double`).
  final int costPoints;

  /// Stock restante; `null` = sin límite.
  final int? stock;

  /// `false` cuando no se puede canjear (p. ej. `stock=0`).
  final bool available;

  /// Inicio de vigencia (ISO 8601 UTC); `null` = sin inicio.
  final DateTime? validFrom;

  /// Fin de vigencia (ISO 8601 UTC); `null` = sin vencimiento.
  final DateTime? validTo;

  /// Comercio que otorga el beneficio.
  final String establishmentId;
}

/// Sucursal de un establecimiento (`BranchSummary`).
final class BranchSummary {
  /// DTO simple.
  const new({required this.id, required this.name, required this.address});

  /// Deserializa el contrato `BranchSummary`.
  factory fromJson(Map<String, Object?> json) => BranchSummary(
    id: json['id']! as String,
    name: json['name']! as String,
    address: json['address']! as String,
  );

  /// Id de la sucursal (uuid).
  final String id;

  /// Nombre de la sucursal (p. ej. "Principal").
  final String name;

  /// Dirección física.
  final String address;
}

/// Establecimiento adherido con sus sucursales (`EstablishmentSummary`).
final class EstablishmentSummary {
  /// DTO simple.
  const new({
    required this.id,
    required this.name,
    required this.category,
    required this.branches,
  });

  /// Deserializa el contrato `EstablishmentSummary`.
  factory fromJson(Map<String, Object?> json) {
    final rawBranches = json['branches'] as List<Object?>? ?? const [];
    return EstablishmentSummary(
      id: json['id']! as String,
      name: json['name']! as String,
      category: json['category']! as String,
      branches: [
        for (final branch in rawBranches)
          BranchSummary.fromJson(Map<String, Object?>.from(branch! as Map)),
      ],
    );
  }

  /// Id del establecimiento (uuid).
  final String id;

  /// Nombre del comercio.
  final String name;

  /// Categoría comercial.
  final String category;

  /// Sucursales activas (toda tienda tiene al menos "Principal").
  final List<BranchSummary> branches;
}
