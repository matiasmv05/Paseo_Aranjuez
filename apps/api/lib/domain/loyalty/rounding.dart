/// Modos de redondeo de la conversion de puntos (FR-012).
///
/// La aritmetica es entera de punta a punta (`AGENTS.md` §2 regla 9): nunca
/// se usa `double`/`float`. La division se hace en [Rounding.divide] sobre
/// entera `dividend / divisor`.
library;

/// Modo de redondeo declarado por una regla de conversion.
enum Rounding {
  floor('FLOOR'),
  round('ROUND'),
  ceil('CEIL');

  const Rounding(this.wire);

  /// Valor textual del contrato (`FLOOR | ROUND | CEIL`).
  final String wire;

  /// Devuelve el modo correspondiente a [value].
  ///
  /// Lanza [FormatException] si no es conocido: una regla con un modo
  /// invalido es un error de datos, no algo que se pueda ignorar en silencio.
  static Rounding fromWire(String value) => values.firstWhere(
    (mode) => mode.wire == value,
    orElse: () => throw FormatException('rounding desconocido: $value'),
  );

  /// Divide `dividend / divisor` con aritmetica entera y este modo.
  ///
  /// `ROUND` redondea medio hacia arriba (`0.5 -> 1`). Multiplicar por 2
  /// antes de dividir evita `double` y no desborda: los operandos de la
  /// conversion son del orden de miles/millones, muy por debajo de 2^62.
  int divide(int dividend, int divisor) {
    if (divisor <= 0) {
      throw ArgumentError.value(divisor, 'divisor', 'debe ser > 0');
    }
    if (dividend < 0) {
      throw ArgumentError.value(dividend, 'dividend', 'debe ser >= 0');
    }
    return switch (this) {
      Rounding.floor => dividend ~/ divisor,
      Rounding.round => (dividend * 2 + divisor) ~/ (divisor * 2),
      Rounding.ceil => (dividend + divisor - 1) ~/ divisor,
    };
  }
}
