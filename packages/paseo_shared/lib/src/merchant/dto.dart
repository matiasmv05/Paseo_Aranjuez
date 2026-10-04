/// DTOs del panel del comercio alineados con `docs/openapi.yaml`.
///
/// Contrato en `snake_case`; campos Dart en camelCase. Sin lógica de
/// dominio: solo serialización (AGENTS.md §3).
library;

// Los DTOs son contenedores planos; los nombres ya se documentan en
// openapi.yaml y replicarlos campo a campo no aporta.
// ignore_for_file: public_member_api_docs

/// `MoneyCents` (docs/openapi.yaml): monto en centavos enteros (`int64`).
///
/// Nunca `double`/`float` para dinero (AGENTS.md §2 regla 9).
typedef MoneyCents = int;

/// `Rounding` del desglose de cálculo: `FLOOR | ROUND | CEIL`.
enum Rounding {
  floor('FLOOR'),
  round('ROUND'),
  ceil('CEIL');

  const Rounding(this.wire);

  /// Valor textual del contrato.
  final String wire;

  static Rounding fromWire(String value) => Rounding.values.firstWhere(
    (mode) => mode.wire == value,
    orElse: () => throw FormatException('rounding desconocido: $value'),
  );
}

/// `CursorPage` (docs/openapi.yaml): envoltura de paginación por cursor.
///
/// Genérico y sin serialización propia: cada página concreta decide cómo
/// decodificar sus elementos. `nextCursor` es `null` en la última página.
final class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

/// `IdentifyRequest` (docs/openapi.yaml): `oneOf` PHONE | QR.
sealed class IdentifyRequest {
  const IdentifyRequest();

  factory IdentifyRequest.fromJson(Map<String, Object?> json) {
    return switch (json['method']) {
      'PHONE' => IdentifyByPhoneRequest.fromJson(json),
      'QR' => IdentifyByQrRequest.fromJson(json),
      final other => throw FormatException(
        'method de identify desconocido: $other',
      ),
    };
  }

  Map<String, Object?> toJson();
}

/// Variante `PHONE` de `IdentifyRequest`.
final class IdentifyByPhoneRequest extends IdentifyRequest {
  const IdentifyByPhoneRequest({required this.phone});

  factory IdentifyByPhoneRequest.fromJson(Map<String, Object?> json) =>
      IdentifyByPhoneRequest(phone: json['phone']! as String);

  /// Teléfono boliviano en E.164 (`+591...`).
  final String phone;

  @override
  Map<String, Object?> toJson() => {'method': 'PHONE', 'phone': phone};
}

/// Variante `QR` de `IdentifyRequest`. `qrToken` es opaco y firmado.
final class IdentifyByQrRequest extends IdentifyRequest {
  const IdentifyByQrRequest({required this.qrToken});

  factory IdentifyByQrRequest.fromJson(Map<String, Object?> json) =>
      IdentifyByQrRequest(qrToken: json['qr_token']! as String);

  final String qrToken;

  @override
  Map<String, Object?> toJson() => {'method': 'QR', 'qr_token': qrToken};
}

/// `IdentifyResponse` de `POST /merchant/customers/identify`.
final class IdentifyResult {
  const IdentifyResult({
    required this.ticket,
    required this.expiresAt,
    required this.customerName,
  });

  factory IdentifyResult.fromJson(Map<String, Object?> json) => IdentifyResult(
    ticket: json['ticket']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String),
    customerName: json['customer_name']! as String,
  );

  /// Ticket opaco y firmado (vida ~5 min).
  final String ticket;
  final DateTime expiresAt;

  /// Nombre enmascarado; el comercio nunca recibe el nombre completo.
  final String customerName;

  Map<String, Object?> toJson() => {
    'ticket': ticket,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'customer_name': customerName,
  };
}

/// `PreviewRequest` de `POST /merchant/purchases/preview`.
///
/// No escribe nada: no pide `invoice_ref` ni `Idempotency-Key`.
final class PreviewPurchaseRequest {
  const PreviewPurchaseRequest({
    required this.ticket,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
  });

  factory PreviewPurchaseRequest.fromJson(Map<String, Object?> json) =>
      PreviewPurchaseRequest(
        ticket: json['ticket']! as String,
        grossCents: json['gross_cents']! as int,
        discountCents: json['discount_cents']! as int,
        netCents: json['net_cents']! as int,
      );

  final String ticket;
  final MoneyCents grossCents;
  final MoneyCents discountCents;
  final MoneyCents netCents;

  Map<String, Object?> toJson() => {
    'ticket': ticket,
    'gross_cents': grossCents,
    'discount_cents': discountCents,
    'net_cents': netCents,
  };
}

/// `CalculationBreakdown` del preview: el cálculo entero, paso a paso.
final class CalculationBreakdown {
  const CalculationBreakdown({
    required this.pointsBase,
    required this.multiplierBp,
    required this.pointsAfterMultiplier,
    required this.pointsBeforeCap,
    required this.capApplied,
    required this.belowMinPurchase,
    required this.rounding,
  });

  factory CalculationBreakdown.fromJson(Map<String, Object?> json) =>
      CalculationBreakdown(
        pointsBase: json['points_base']! as int,
        multiplierBp: json['multiplier_bp']! as int,
        pointsAfterMultiplier: json['points_after_multiplier']! as int,
        pointsBeforeCap: json['points_before_cap']! as int,
        capApplied: json['cap_applied']! as bool,
        belowMinPurchase: json['below_min_purchase']! as bool,
        rounding: Rounding.fromWire(json['rounding']! as String),
      );

  final int pointsBase;

  /// Basis points: `10000` es ×1. `0` significa «sin multiplicador».
  final int multiplierBp;
  final int pointsAfterMultiplier;

  /// Valor antes del tope; se conserva para auditar el tope.
  final int pointsBeforeCap;
  final bool capApplied;

  /// `true` → los puntos son `0` por estar bajo la compra mínima.
  final bool belowMinPurchase;
  final Rounding rounding;

  Map<String, Object?> toJson() => {
    'points_base': pointsBase,
    'multiplier_bp': multiplierBp,
    'points_after_multiplier': pointsAfterMultiplier,
    'points_before_cap': pointsBeforeCap,
    'cap_applied': capApplied,
    'below_min_purchase': belowMinPurchase,
    'rounding': rounding.wire,
  };
}

/// `PurchasePreviewResponse` de `POST /merchant/purchases/preview`.
final class PreviewPurchaseResult {
  const PreviewPurchaseResult({
    required this.points,
    required this.ruleId,
    required this.campaignRuleId,
    required this.breakdown,
  });

  factory PreviewPurchaseResult.fromJson(Map<String, Object?> json) =>
      PreviewPurchaseResult(
        points: json['points']! as int,
        ruleId: json['rule_id']! as String,
        campaignRuleId: json['campaign_rule_id'] as String?,
        breakdown: CalculationBreakdown.fromJson(
          (json['breakdown']! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
      );

  final int points;
  final String ruleId;

  /// Campaña vigente aplicada, o `null`. Como máximo una.
  final String? campaignRuleId;
  final CalculationBreakdown breakdown;

  Map<String, Object?> toJson() => {
    'points': points,
    'rule_id': ruleId,
    'campaign_rule_id': campaignRuleId,
    'breakdown': breakdown.toJson(),
  };
}

/// `PurchaseRequest` de `POST /merchant/purchases`.
///
/// Acepta **solo el ticket**: nunca un teléfono ni un `customer_id` (FR-007).
final class RegisterPurchaseRequest {
  const RegisterPurchaseRequest({
    required this.ticket,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.invoiceRef,
  });

  factory RegisterPurchaseRequest.fromJson(Map<String, Object?> json) =>
      RegisterPurchaseRequest(
        ticket: json['ticket']! as String,
        grossCents: json['gross_cents']! as int,
        discountCents: json['discount_cents']! as int,
        netCents: json['net_cents']! as int,
        invoiceRef: json['invoice_ref']! as String,
      );

  final String ticket;
  final MoneyCents grossCents;
  final MoneyCents discountCents;
  final MoneyCents netCents;

  /// Obligatoria; única por `(establishment_id, invoice_ref)` en el comercio.
  final String invoiceRef;

  Map<String, Object?> toJson() => {
    'ticket': ticket,
    'gross_cents': grossCents,
    'discount_cents': discountCents,
    'net_cents': netCents,
    'invoice_ref': invoiceRef,
  };
}

/// `PurchaseResponse` de `POST /merchant/purchases` (200 y 201).
final class Purchase {
  const Purchase({
    required this.id,
    required this.invoiceRef,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.pointsCredited,
    required this.ruleId,
    required this.campaignRuleId,
    required this.createdAt,
  });

  factory Purchase.fromJson(Map<String, Object?> json) => Purchase(
    id: json['id']! as String,
    invoiceRef: json['invoice_ref']! as String,
    grossCents: json['gross_cents']! as int,
    discountCents: json['discount_cents']! as int,
    netCents: json['net_cents']! as int,
    pointsCredited: json['points_credited']! as int,
    ruleId: json['rule_id']! as String,
    campaignRuleId: json['campaign_rule_id'] as String?,
    createdAt: DateTime.parse(json['created_at']! as String),
  );

  final String id;
  final String invoiceRef;
  final MoneyCents grossCents;
  final MoneyCents discountCents;
  final MoneyCents netCents;

  /// `0` cuando el importe quedó bajo la compra mínima (sin fila en el ledger).
  final int pointsCredited;
  final String ruleId;
  final String? campaignRuleId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'invoice_ref': invoiceRef,
    'gross_cents': grossCents,
    'discount_cents': discountCents,
    'net_cents': netCents,
    'points_credited': pointsCredited,
    'rule_id': ruleId,
    'campaign_rule_id': campaignRuleId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

/// `MerchantMovement` de `GET /merchant/movements`.
final class MerchantMovement {
  const MerchantMovement({
    required this.id,
    required this.createdAt,
    required this.invoiceRef,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.pointsCredited,
    required this.customerName,
    required this.branchId,
  });

  factory MerchantMovement.fromJson(Map<String, Object?> json) =>
      MerchantMovement(
        id: json['id']! as String,
        createdAt: DateTime.parse(json['created_at']! as String),
        invoiceRef: json['invoice_ref']! as String,
        grossCents: json['gross_cents']! as int,
        discountCents: json['discount_cents']! as int,
        netCents: json['net_cents']! as int,
        pointsCredited: json['points_credited']! as int,
        customerName: json['customer_name']! as String,
        branchId: json['branch_id']! as String,
      );

  final String id;
  final DateTime createdAt;
  final String invoiceRef;
  final MoneyCents grossCents;
  final MoneyCents discountCents;
  final MoneyCents netCents;
  final int pointsCredited;
  final String customerName;

  /// Sucursal donde se registró la compra (siempre del servidor).
  final String branchId;

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at': createdAt.toUtc().toIso8601String(),
    'invoice_ref': invoiceRef,
    'gross_cents': grossCents,
    'discount_cents': discountCents,
    'net_cents': netCents,
    'points_credited': pointsCredited,
    'customer_name': customerName,
    'branch_id': branchId,
  };
}

/// `MerchantMovementPage`: `CursorPage<MerchantMovement>`, orden
/// `created_at DESC, id DESC`.
final class MerchantMovementPage extends CursorPage<MerchantMovement> {
  const MerchantMovementPage({required super.items, super.nextCursor});

  factory MerchantMovementPage.fromJson(Map<String, Object?> json) =>
      MerchantMovementPage(
        items: (json['items']! as List<Object?>)
            .map(
              (item) => MerchantMovement.fromJson(
                (item! as Map<Object?, Object?>).cast<String, Object?>(),
              ),
            )
            .toList(growable: false),
        nextCursor: json['next_cursor'] as String?,
      );

  Map<String, Object?> toJson() => {
    'items': items.map((movement) => movement.toJson()).toList(growable: false),
    'next_cursor': nextCursor,
  };
}
