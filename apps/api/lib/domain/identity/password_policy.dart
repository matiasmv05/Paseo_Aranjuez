import 'errors.dart';

/// Politica de contrasenas del MVP (validacion de forma; el hash Argon2id
/// vive tras el puerto `PasswordHasher`).
abstract final class PasswordPolicy {
  static const minLength = 8;
  static const maxLength = 128;

  /// Lanza `IdentityException` con `VALIDATION_FAILED` si no cumple.
  static void validate(String password) {
    if (password.length < minLength) {
      throw IdentityException.validation(
        'contrasena demasiado corta (minimo $minLength)',
      );
    }
    if (password.length > maxLength) {
      throw IdentityException.validation('contrasena demasiado larga');
    }
  }
}
