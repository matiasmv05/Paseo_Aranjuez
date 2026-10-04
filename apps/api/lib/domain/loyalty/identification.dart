/// Tipos puros de identificacion del cliente (HU-10, FR-003/FR-006).
///
/// El ticket de identificacion y el token QR comparten primitiva de firma
/// (HMAC-SHA256, `IdentificationSigner`) pero no formato ni TTL: el ticket
/// vive ~300 s y el QR ~60 s. Ambos viven fuera del JWT de sesion y no
/// llevan datos personales (SEC-001/SEC-005); el nombre del cliente se
/// resuelve despues y se devuelve enmascarado (FR-003).
///
/// Este archivo no firma ni verifica: solo describe el sobre y sus claims.
library;

/// Tipo de token firmado; viaja como `kind` para que un token QR no pueda
/// pasar por ticket de identificacion.
enum IdentificationTokenKind {
  ticket('ticket'),
  qr('qr');

  const IdentificationTokenKind(this.wire);

  /// Valor serializado en el sobre.
  final String wire;

  /// Devuelve el `kind` correspondiente o `null` si no es conocido.
  static IdentificationTokenKind? fromWire(String value) {
    for (final kind in values) {
      if (kind.wire == value) {
        return kind;
      }
    }
    return null;
  }
}

/// Claims del ticket de identificacion (FR-003, FR-007, FR-017).
///
/// Atado al `establishmentId` de quien identifica y a su `branchId` si es
/// cajero; el dueno no fija sucursal (`branchId == null`). El cliente nunca
/// lo ve ni lo forja: es opaco y firmado (SEC-005).
final class IdentificationTicketClaims {
  const IdentificationTicketClaims({
    required this.customerId,
    required this.establishmentId,
    required this.branchId,
    required this.issuedAt,
    required this.expiresAt,
  });

  /// Vida por defecto: 300 s (`IDENTIFICATION_TICKET_TTL_SECONDS`).
  static const ttl = Duration(minutes: 5);

  /// Tipo de token que representa este sobre.
  static const IdentificationTokenKind kind = IdentificationTokenKind.ticket;

  /// Cliente identificado; jamas sale en la respuesta (FR-003).
  final String customerId;

  /// Comercio del llamador; el ticket no sirve en otro (FR-007).
  final String establishmentId;

  /// Sucursal del cajero; `null` para el dueno (FR-017).
  final String? branchId;

  /// Emision y vencimiento en UTC.
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// Duracion efectiva entre emision y vencimiento.
  Duration get lifetime => expiresAt.difference(issuedAt);

  Map<String, Object?> toJson() => {
    'v': 1,
    'kind': kind.wire,
    'cid': customerId,
    'est': establishmentId,
    if (branchId != null) 'br': branchId,
    'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };

  /// Reconstruye los claims; `null` si el sobre no es un ticket valido.
  static IdentificationTicketClaims? fromJson(Map<String, Object?> json) {
    final customerId = json['cid'];
    final establishmentId = json['est'];
    final branchId = json['br'];
    final issuedAt = _secondsToUtc(json['iat']);
    final expiresAt = _secondsToUtc(json['exp']);
    if (json['v'] != 1 ||
        json['kind'] != kind.wire ||
        customerId is! String ||
        customerId.isEmpty ||
        establishmentId is! String ||
        establishmentId.isEmpty ||
        (branchId != null && (branchId is! String || branchId.isEmpty)) ||
        issuedAt == null ||
        expiresAt == null) {
      return null;
    }
    return IdentificationTicketClaims(
      customerId: customerId,
      establishmentId: establishmentId,
      branchId: branchId as String?,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }
}

/// Claims del token QR del cliente (FR-006, HU-03 de Persona 1).
///
/// Esta feature **valida** el token, no lo emite. No esta atado a un
/// comercio: lo emite la app del cliente y lo escanea cualquier cajero.
final class QrTokenClaims {
  const QrTokenClaims({
    required this.customerId,
    required this.issuedAt,
    required this.expiresAt,
  });

  /// Vida por defecto: 60 s (`QR_TOKEN_TTL_SECONDS`).
  static const ttl = Duration(seconds: 60);

  /// Tipo de token que representa este sobre.
  static const IdentificationTokenKind kind = IdentificationTokenKind.qr;

  /// Cliente al que pertenece el QR.
  final String customerId;

  /// Emision y vencimiento en UTC.
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// Duracion efectiva entre emision y vencimiento.
  Duration get lifetime => expiresAt.difference(issuedAt);

  Map<String, Object?> toJson() => {
    'v': 1,
    'kind': kind.wire,
    'cid': customerId,
    'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };

  /// Reconstruye los claims; `null` si el sobre no es un QR valido.
  static QrTokenClaims? fromJson(Map<String, Object?> json) {
    final customerId = json['cid'];
    final issuedAt = _secondsToUtc(json['iat']);
    final expiresAt = _secondsToUtc(json['exp']);
    if (json['v'] != 1 ||
        json['kind'] != kind.wire ||
        customerId is! String ||
        customerId.isEmpty ||
        issuedAt == null ||
        expiresAt == null) {
      return null;
    }
    return QrTokenClaims(
      customerId: customerId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }
}

/// Enmascara el nombre de un cliente para exponerlo al comercio (FR-003).
///
/// El nombre completo nunca sale en una respuesta del panel (§8): se
/// conserva el primer nombre y se reducen los apellidos a su inicial. Un
/// nombre de una sola palabra queda como inicial seguida de punto.
String maskCustomerName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  final first = parts.first;
  if (parts.length == 1) {
    return '${first.substring(0, 1).toUpperCase()}.';
  }
  final initials = parts
      .skip(1)
      .map((part) => '${part.substring(0, 1).toUpperCase()}.')
      .join(' ');
  return '$first $initials';
}

DateTime? _secondsToUtc(Object? value) {
  if (value is! int || value < 0) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
}
