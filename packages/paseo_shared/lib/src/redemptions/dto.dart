/// DTOs de canjes, validaciones y gamificación para Persona 5.
///
/// Contrato en `snake_case`; campos Dart en camelCase.
library;

// Los DTOs son contenedores de contrato documentados en openapi.yaml.
// ignore_for_file: public_member_api_docs

/// Solicitud de emisión de cupón de canje (HU-07).
final class RedemptionIssueRequest {
  const new({required this.rewardId});

  factory fromJson(Map<String, Object?> json) =>
      RedemptionIssueRequest(rewardId: json['reward_id']! as String);

  final String rewardId;

  Map<String, Object?> toJson() => {'reward_id': rewardId};
}

/// Respuesta de cupón de canje generado exitosamente (HU-07).
final class RedemptionIssueResponse {
  const new({
    required this.id,
    required this.code,
    required this.rewardId,
    required this.pointsSpent,
    required this.status,
    required this.expiresAt,
  });

  factory fromJson(Map<String, Object?> json) => RedemptionIssueResponse(
    id: json['id']! as String,
    code: json['code']! as String,
    rewardId: json['reward_id']! as String,
    pointsSpent: json['points_spent']! as int,
    status: json['status']! as String,
    expiresAt: json['expires_at']! as String,
  );

  final String id;
  final String code;
  final String rewardId;
  final int pointsSpent;
  final String status;
  final String expiresAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'reward_id': rewardId,
    'points_spent': pointsSpent,
    'status': status,
    'expires_at': expiresAt,
  };
}

/// Solicitud de validación de cupón de canje por el comercio (HU-12).
final class RedemptionValidateRequest {
  const new({required this.code});

  factory fromJson(Map<String, Object?> json) =>
      RedemptionValidateRequest(code: json['code']! as String);

  final String code;

  Map<String, Object?> toJson() => {'code': code};
}

/// Resultado de la verificación de un cupón en caja (HU-12).
final class RedemptionValidateResponse {
  const new({
    required this.redemptionId,
    required this.rewardTitle,
    required this.customerMaskedName,
    required this.status,
    required this.canRedeem,
    this.establishmentId,
  });

  factory fromJson(Map<String, Object?> json) => RedemptionValidateResponse(
    redemptionId: json['redemption_id']! as String,
    rewardTitle: json['reward_title']! as String,
    customerMaskedName: json['customer_masked_name']! as String,
    status: json['status']! as String,
    canRedeem: json['can_redeem']! as bool,
    establishmentId: json['establishment_id'] as String?,
  );

  final String redemptionId;
  final String rewardTitle;
  final String customerMaskedName;
  final String status;
  final bool canRedeem;
  final String? establishmentId;

  Map<String, Object?> toJson() => {
    'redemption_id': redemptionId,
    'reward_title': rewardTitle,
    'customer_masked_name': customerMaskedName,
    'status': status,
    'can_redeem': canRedeem,
    if (establishmentId != null) 'establishment_id': establishmentId,
  };
}

/// Solicitud para marcar como entregado y consumido un cupón (HU-12).
final class RedemptionCompleteRequest {
  const new({required this.code});

  factory fromJson(Map<String, Object?> json) =>
      RedemptionCompleteRequest(code: json['code']! as String);

  final String code;

  Map<String, Object?> toJson() => {'code': code};
}

/// Respuesta tras consumar la entrega de la recompensa (HU-12).
final class RedemptionCompleteResponse {
  const new({
    required this.redemptionId,
    required this.status,
    required this.completedAt,
  });

  factory fromJson(Map<String, Object?> json) => RedemptionCompleteResponse(
    redemptionId: json['redemption_id']! as String,
    status: json['status']! as String,
    completedAt: json['completed_at']! as String,
  );

  final String redemptionId;
  final String status;
  final String completedAt;

  Map<String, Object?> toJson() => {
    'redemption_id': redemptionId,
    'status': status,
    'completed_at': completedAt,
  };
}

/// DTO del nivel de lealtad y gamificación del cliente (HU-22).
final class CustomerTierDto {
  const new({
    required this.tier,
    required this.points,
    required this.nextTier,
    required this.pointsToNextTier,
    required this.progressPercentage,
    required this.multiplier,
    required this.benefits,
  });

  factory fromJson(Map<String, Object?> json) => CustomerTierDto(
    tier: json['tier']! as String,
    points: json['points']! as int,
    nextTier: json['next_tier'] as String?,
    pointsToNextTier: json['points_to_next_tier'] as int?,
    progressPercentage: (json['progress_percentage']! as num).toDouble(),
    multiplier: (json['multiplier']! as num).toDouble(),
    benefits: (json['benefits']! as List<Object?>).cast<String>(),
  );

  final String tier;
  final int points;
  final String? nextTier;
  final int? pointsToNextTier;
  final double progressPercentage;
  final double multiplier;
  final List<String> benefits;

  Map<String, Object?> toJson() => {
    'tier': tier,
    'points': points,
    'next_tier': nextTier,
    'points_to_next_tier': pointsToNextTier,
    'progress_percentage': progressPercentage,
    'multiplier': multiplier,
    'benefits': benefits,
  };
}

/// Solicitud de propuesta de promoción del comercio (HU-14).
final class PromotionProposalRequest {
  const new({
    required this.title,
    required this.description,
    required this.badge,
    required this.validUntil,
  });

  factory fromJson(Map<String, Object?> json) => PromotionProposalRequest(
    title: json['title']! as String,
    description: json['description']! as String,
    badge: json['badge']! as String,
    validUntil: json['valid_until']! as String,
  );

  final String title;
  final String description;
  final String badge;
  final String validUntil;

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'badge': badge,
    'valid_until': validUntil,
  };
}

/// Respuesta de propuesta de promoción enviada para aprobación (HU-14).
final class PromotionProposalResponse {
  const new({
    required this.id,
    required this.title,
    required this.status,
    required this.submittedAt,
  });

  factory fromJson(Map<String, Object?> json) => PromotionProposalResponse(
    id: json['id']! as String,
    title: json['title']! as String,
    status: json['status']! as String,
    submittedAt: json['submitted_at']! as String,
  );

  final String id;
  final String title;
  final String status;
  final String submittedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'submitted_at': submittedAt,
  };
}
