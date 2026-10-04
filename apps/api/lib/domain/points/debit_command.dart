/// Comando para debitar puntos de un cliente.
class DebitCommand {
  /// Crea un nuevo comando de débito.
  ///
  /// Lanza [ArgumentError] si [points] <= 0 o [reference] está vacía.
  DebitCommand({required this.points, required this.reference}) {
    if (points <= 0) {
      throw ArgumentError('Los puntos deben ser mayores a 0: $points');
    }

    if (reference.trim().isEmpty) {
      throw ArgumentError('La referencia no puede estar vacía');
    }
  }

  /// Puntos a debitar (debe ser > 0)
  final int points;

  /// Referencia del movimiento (no puede estar vacía)
  final String reference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebitCommand &&
          runtimeType == other.runtimeType &&
          points == other.points &&
          reference == other.reference;

  @override
  int get hashCode => Object.hash(points, reference);

  @override
  String toString() => 'DebitCommand(points: $points, reference: $reference)';
}
