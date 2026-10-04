import '../../features/identity/data/http_auth_repository.dart';
import '../../features/identity/data/mock_auth_repository.dart';
import '../../features/identity/domain/auth_repository.dart';

/// Contenedor simple de dependencias (service locator) del app móvil.
///
/// Configuración por entorno:
/// `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=...`
final class InjectionContainer {
  InjectionContainer._();

  static AuthRepository? _authRepository;

  /// Repositorio de identidad configurado. Si no se llamó a
  /// [setupDependencies], devuelve un [MockAuthRepository] (defecto seguro).
  static AuthRepository get authRepository =>
      _authRepository ?? MockAuthRepository();

  /// Inicializa el contenedor. [useMock] por defecto lee el
  /// `--dart-define=USE_MOCK` (true en desarrollo/tests si no se especifica).
  static void setupDependencies({bool? useMock, String? baseUrl}) {
    final resolvedUseMock =
        useMock ?? const bool.fromEnvironment('USE_MOCK', defaultValue: true);
    final resolvedBaseUrl =
        baseUrl ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:8080',
        );
    _authRepository = resolvedUseMock
        ? MockAuthRepository()
        : HttpAuthRepository(baseUrl: resolvedBaseUrl);
  }

  /// Limpia el contenedor (útil entre tests).
  static void reset() {
    _authRepository = null;
  }
}
