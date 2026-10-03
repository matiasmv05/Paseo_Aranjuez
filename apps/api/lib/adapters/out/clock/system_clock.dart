import 'package:paseo_api/application/identity/ports.dart';

/// Reloj de sistema (UTC).
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
