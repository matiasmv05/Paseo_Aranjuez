import 'errors.dart';

/// Correo electronico validado (objeto de valor). Se normaliza a minusculas;
/// la unicidad `citext` la garantiza la base.
final class Email {
  const Email._(this.value);

  /// Normaliza (trim + minusculas) y valida formato basico.
  factory Email.parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (!_regex.hasMatch(value)) {
      throw IdentityException.validation('correo invalido');
    }
    return Email._(value);
  }

  static final _regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final String value;

  @override
  bool operator ==(Object other) => other is Email && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
