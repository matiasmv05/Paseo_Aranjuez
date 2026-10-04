/// Formatea puntos enteros con separador de miles (`.`); los negativos llevan
/// su signo. Los puntos son siempre enteros (regla 9 de AGENTS.md).
String formatPoints(int points) {
  final isNegative = points < 0;
  final digits = points.abs().toString();
  final buffer = StringBuffer(isNegative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i - 1;
    buffer.write(digits[i]);
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

/// Formatea el delta de un movimiento con signo explícito (`+1.250`, `-500`).
String formatSignedPoints(int delta) =>
    '${delta >= 0 ? '+' : ''}${formatPoints(delta)}';

/// Fecha legible en hora local: `03/10/2026 18:45`.
///
/// Las fechas de la API llegan en ISO 8601 UTC (AGENTS.md §9).
String formatDateTime(DateTime utc) {
  final local = utc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Solo la fecha, en hora local: `03/10/2026`.
String formatDate(DateTime utc) {
  final local = utc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
