import 'package:paseo_api/application/identity/ports.dart';
import 'package:uuid/uuid.dart';

/// Generador de UUID v4.
final class UuidIdGenerator implements IdGenerator {
  const new();

  @override
  String newId() => const Uuid().v4();
}
