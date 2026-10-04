/// Rate limit por `establishment_id` para `preview`/`purchases` (FR-025).
///
/// Implementacion in-memory de ventana fija (suficiente para una sola
/// instancia; si el despliegue escala horizontalmente se sustituye por un
/// store compartido manteniendo este puerto). Nunca registra PII (§8).
library;

import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';

/// Estado de una ventana fija para un par (comercio, accion).
final class _Window {
  _Window(this.resetAt);

  int hits = 0;
  DateTime resetAt;
}

/// Limita por comercio y accion usando una ventana de tiempo deslizante.
///
/// Cada par (`establishmentId`, [MerchantAction]) tiene su propio contador;
/// el limite es configurable y por defecto 60 peticiones por minuto.
final class EstablishmentRateLimiter implements RateLimiter {
  /// Crea el limitador; inyecta el [clock] para poder testear el paso del
  /// tiempo sin depender del reloj del sistema.
  EstablishmentRateLimiter({
    required Clock clock,
    this.limit = 60,
    this.window = const Duration(minutes: 1),
  }) : _clock = clock;

  final Clock _clock;

  /// Maximo de peticiones permitidas por ventana.
  final int limit;

  /// Duracion de la ventana de conteo.
  final Duration window;

  final Map<String, _Window> _windows = {};

  @override
  Future<bool> tryAcquire({
    required String establishmentId,
    required MerchantAction action,
  }) {
    final now = _clock.nowUtc();
    final key = '$establishmentId:${action.wire}';
    _prune(now);

    final current = _windows[key];
    if (current == null || !now.isBefore(current.resetAt)) {
      _windows[key] = _Window(now.add(window))..hits = 1;
      return Future.value(true);
    }
    if (current.hits >= limit) {
      return Future.value(false);
    }
    current.hits++;
    return Future.value(true);
  }

  /// Elimina ventanas vencidas para que el mapa no crezca sin limite.
  void _prune(DateTime now) {
    _windows.removeWhere((_, window) => !now.isBefore(window.resetAt));
  }
}
