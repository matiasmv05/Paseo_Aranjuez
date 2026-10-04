import 'dart:convert';

/// Utilidades para codificación/decodificación de cursors de paginación.
class PointsCursor {
  /// Codifica occurred_at y ledger_id como cursor base64.
  static String encode({
    required DateTime occurredAt,
    required String ledgerId,
  }) {
    final data = {
      'occurredAt': occurredAt.toIso8601String(),
      'ledgerId': ledgerId,
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  /// Decodifica un cursor base64 a CursorData.
  ///
  /// Lanza [FormatException] si el cursor es inválido.
  static CursorData decode(String cursor) {
    try {
      final bytes = base64Decode(cursor);
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final occurredAtString = data['occurredAt'] as String?;
      final ledgerId = data['ledgerId'] as String?;

      if (occurredAtString == null || ledgerId == null) {
        throw const FormatException('Cursor structure is invalid');
      }

      final occurredAt = DateTime.parse(occurredAtString);

      return CursorData(occurredAt: occurredAt, ledgerId: ledgerId);
    } catch (e) {
      throw FormatException('Invalid cursor format: $e');
    }
  }
}

/// Datos decodificados de un cursor de paginación.
class CursorData {
  /// Crea nuevos datos de cursor.
  const CursorData({required this.occurredAt, required this.ledgerId});

  /// Timestamp del movimiento
  final DateTime occurredAt;

  /// ID del registro en el ledger
  final String ledgerId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorData &&
          runtimeType == other.runtimeType &&
          occurredAt == other.occurredAt &&
          ledgerId == other.ledgerId;

  @override
  int get hashCode => Object.hash(occurredAt, ledgerId);

  @override
  String toString() =>
      'CursorData(occurredAt: $occurredAt, ledgerId: $ledgerId)';
}
