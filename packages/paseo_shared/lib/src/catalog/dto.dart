/// DTOs de catálogo alineados con `docs/openapi.yaml` (schemas
/// `RewardSummary`, `EstablishmentSummary`, `BranchSummary`).
///
/// Contrato en `snake_case`; campos Dart en camelCase. Sin lógica de
/// dominio: solo serialización. Los campos administrativos
/// (`approved_by`, `max_purchase_cents`, `compliance_status`, …) nunca
/// forman parte de estos DTOs (spec 002, US4/US5).
library;

// Los DTOs son contenedores planos; los nombres ya se documentan en
// openapi.yaml y replicarlos campo a campo no aporta.
// ignore_for_file: public_member_api_docs

/// `RewardSummary`: resumen de recompensa en el catálogo (HU-06).
final class RewardSummary {
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

  factory fromJson(Map<String, Object?> json) {
    final validFrom = json['valid_from'] as String?;
    final validTo = json['valid_to'] as String?;
    return RewardSummary(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      rewardType: json['reward_type']! as String,
      costPoints: json['cost_points']! as int,
      stock: json['stock'] as int?,
      available: json['available']! as bool,
      validFrom: validFrom == null ? null : DateTime.parse(validFrom),
      validTo: validTo == null ? null : DateTime.parse(validTo),
      establishmentId: json['establishment_id']! as String,
    );
  }

  final String id;
  final String name;
  final String description;

  /// PERCENT | FIXED | GIFT.
  final String rewardType;
  final int costPoints;

  /// `null` = sin límite.
  final int? stock;
  final bool available;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String establishmentId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'reward_type': rewardType,
    'cost_points': costPoints,
    'stock': stock,
    'available': available,
    'valid_from': validFrom?.toIso8601String(),
    'valid_to': validTo?.toIso8601String(),
    'establishment_id': establishmentId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardSummary &&
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

/// `BranchSummary`: sucursal de un establecimiento (HU-09).
final class BranchSummary {
  const new({required this.id, required this.name, required this.address});

  factory fromJson(Map<String, Object?> json) => BranchSummary(
    id: json['id']! as String,
    name: json['name']! as String,
    address: json['address']! as String,
  );

  final String id;
  final String name;
  final String address;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'address': address};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchSummary &&
          id == other.id &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => Object.hash(id, name, address);
}

/// `EstablishmentSummary`: vista de cliente; nunca campos administrativos.
final class EstablishmentSummary {
  const new({
    required this.id,
    required this.name,
    required this.category,
    required this.branches,
  });

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

  final String id;
  final String name;
  final String category;
  final List<BranchSummary> branches;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'branches': [for (final b in branches) b.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstablishmentSummary &&
          id == other.id &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => Object.hash(id, name, category);
}
