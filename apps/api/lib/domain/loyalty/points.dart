/// Objeto de valor de puntos enteros, `>= 0`.
///
/// Ningun movimiento de puntos puede ser negativo (`AGENTS.md` §2 regla 3):
/// el saldo lo garantiza la base, pero el tipo lo codifica antes.
library;

/// Cantidad de puntos, `>= 0`.
final class Points implements Comparable<Points> {
  const Points._(this.value);

  /// Crea una cantidad; lanza [ArgumentError] si [value] es negativo.
  factory Points(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'no puede ser negativo');
    }
    return Points._(value);
  }

  /// Cantidad cero.
  static const zero = Points._(0);

  /// Numero de puntos.
  final int value;

  /// Suma de puntos.
  Points operator +(Points other) => Points(value + other.value);

  bool operator <(Points other) => value < other.value;
  bool operator <=(Points other) => value <= other.value;
  bool operator >(Points other) => value > other.value;
  bool operator >=(Points other) => value >= other.value;

  @override
  int compareTo(Points other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Points && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
