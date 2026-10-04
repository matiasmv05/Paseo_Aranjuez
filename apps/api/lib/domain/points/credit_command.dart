/// Comando para acreditar puntos a un cliente.
class CreditCommand {
  /// Crea un nuevo comando de crédito.
  ///
  /// Lanza [ArgumentError] si [points] <= 0 o [reference] está vacía.
  CreditCommand({required this.points, required this.reference}) {
    if (points <= 0) {
      throw ArgumentError('Los puntos deben ser mayores a 0: $points');
    }

    if (reference.trim().isEmpty) {
      throw ArgumentError('La referencia no puede estar vacía');
    }
  }

  /// Puntos a acreditar (debe ser > 0)
  final int points;

  /// Referencia del movimiento (no puede estar vacía)
  final String reference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCommand &&
          runtimeType == other.runtimeType &&
          points == other.points &&
          reference == other.reference;

  @override
  int get hashCode => Object.hash(points, reference);

  @override
  String toString() => 'CreditCommand(points: $points, reference: $reference)';
}
