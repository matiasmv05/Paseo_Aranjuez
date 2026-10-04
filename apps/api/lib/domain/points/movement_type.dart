/// Tipos de movimientos en el ledger de puntos.
///
/// El valor del enum es `snake`/minúsculas (Dart); [wire] expone el valor
/// exacto de `points_ledger.type` y del contrato `Movement.type`
/// (MAYÚSCULAS: `CREDIT`, `REDEEM`, `ADJUST`, `BONUS`, `REVERSAL`).
/// [origin] mapea al contrato `Movement.origin`
/// (`purchase|redemption|adjustment|reversal`); `bonus` comparte el
/// origen `adjustment` (no existe origen `bonus` en el contrato).
enum MovementType {
  /// Acreditación de puntos por compra.
  credit,

  /// Canje/redención de puntos por recompensa.
  redeem,

  /// Ajuste manual (positivo o negativo).
  adjust,

  /// Bonus promocional.
  bonus,

  /// Reversión de un movimiento anterior.
  reversal;

  /// Valor exacto de `points_ledger.type` y del contrato `Movement.type`
  /// (MAYÚSCULAS).
  String get wire => name.toUpperCase();

  /// Origen funcional del contrato `Movement.origin` (HU-05).
  String get origin => switch (this) {
    MovementType.credit => 'purchase',
    MovementType.redeem => 'redemption',
    MovementType.adjust => 'adjustment',
    MovementType.bonus => 'adjustment',
    MovementType.reversal => 'reversal',
  };

  /// Parsea desde el valor del ledger/contrato (MAYÚSCULAS). Lanza
  /// [FormatException] si no coincide con ningún tipo.
  static MovementType parseWire(String wire) {
    for (final t in MovementType.values) {
      if (t.wire == wire) return t;
    }
    throw FormatException('MovementType desconocido: $wire');
  }
}
