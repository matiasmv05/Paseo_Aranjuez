import 'errors.dart';

/// Telefono boliviano en E.164 (objeto de valor).
///
/// FR-002: solo `+591`. Regex laxa `^\+591[0-9]{8}$` hasta verificar la
/// regla de numeracion (spec 001, OPEN_DECISIONS). Un prefijo distinto de
/// `+591` lanza `PHONE_NOT_SUPPORTED`; un `+591` mal formado es
/// `VALIDATION_FAILED`.
final class PhoneBO {
  const PhoneBO._(this.value);

  factory PhoneBO.parse(String raw) {
    final value = raw.trim();
    if (!value.startsWith('+591')) {
      throw IdentityException.phoneNotSupported();
    }
    if (!_regex.hasMatch(value)) {
      throw IdentityException.validation('telefono invalido');
    }
    return PhoneBO._(value);
  }

  static final _regex = RegExp(r'^\+591[0-9]{8}$');

  /// Valor E.164 (`+591XXXXXXXX`).
  final String value;

  @override
  bool operator ==(Object other) => other is PhoneBO && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
