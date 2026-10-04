/// Objeto de valor de dinero en centavos enteros (`MoneyCents`).
///
/// Nunca `double`/`float` para dinero (`AGENTS.md` §2 regla 9). Un monto no
/// puede ser negativo: `gross_cents`, `discount_cents` y `net_cents` lo son.
library;

/// Monto en centavos enteros, `>= 0`.
final class Cents implements Comparable<Cents> {
  const Cents._(this.value);

  /// Crea un monto; lanza [ArgumentError] si [value] es negativo.
  factory Cents(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'no puede ser negativo');
    }
    return Cents._(value);
  }

  /// Monto cero.
  static const zero = Cents._(0);

  /// Cantidad de centavos.
  final int value;

  /// Suma de montos.
  Cents operator +(Cents other) => Cents(value + other.value);

  /// Resta; lanza [ArgumentError] si el resultado seria negativo.
  Cents operator -(Cents other) {
    final result = value - other.value;
    if (result < 0) {
      throw ArgumentError('resultado negativo: $value - ${other.value}');
    }
    return Cents._(result);
  }

  /// Multiplica por un factor entero no negativo.
  Cents operator *(int factor) {
    if (factor < 0) {
      throw ArgumentError.value(factor, 'factor', 'no puede ser negativo');
    }
    return Cents._(value * factor);
  }

  bool operator <(Cents other) => value < other.value;
  bool operator <=(Cents other) => value <= other.value;
  bool operator >(Cents other) => value > other.value;
  bool operator >=(Cents other) => value >= other.value;

  @override
  int compareTo(Cents other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Cents && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
