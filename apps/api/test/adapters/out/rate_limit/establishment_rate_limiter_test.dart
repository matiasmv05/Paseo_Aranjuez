import 'package:paseo_api/adapters/out/rate_limit/establishment_rate_limiter.dart';
import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:test/test.dart';

/// Reloj mutable para simular el paso del tiempo entre peticiones.
final class _MutableClock implements Clock {
  _MutableClock(this._now);

  DateTime _now;

  void advance(Duration delta) => _now = _now.add(delta);

  @override
  DateTime nowUtc() => _now;
}

void main() {
  late _MutableClock clock;
  late EstablishmentRateLimiter limiter;

  setUp(() {
    clock = _MutableClock(DateTime.utc(2026, 10, 3, 12));
    limiter = EstablishmentRateLimiter(clock: clock, limit: 2);
  });

  test('permite hasta el limite y luego rechaza (429)', () async {
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      ),
      isTrue,
    );
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      ),
      isTrue,
    );
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      ),
      isFalse,
    );
  });

  test('vuelve a permitir cuando la ventana expira', () async {
    for (var i = 0; i < 2; i++) {
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      );
    }
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      ),
      isFalse,
    );

    clock.advance(const Duration(minutes: 1));
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.preview,
      ),
      isTrue,
    );
  });

  test('el contador es independiente por comercio y por accion', () async {
    await limiter.tryAcquire(
      establishmentId: 'est-1',
      action: MerchantAction.preview,
    );
    await limiter.tryAcquire(
      establishmentId: 'est-1',
      action: MerchantAction.preview,
    );

    // Otro comercio no se ve afectado.
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-2',
        action: MerchantAction.preview,
      ),
      isTrue,
    );
    // La misma accion en otra clave sigue disponible para est-1.
    expect(
      await limiter.tryAcquire(
        establishmentId: 'est-1',
        action: MerchantAction.registerPurchase,
      ),
      isTrue,
    );
  });
}
