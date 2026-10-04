/// Capa de aplicación del módulo de puntos (feature 002).
///
/// Casos de uso de escritura (`CreditPoints`, `DebitPoints`) y puertos de
/// persistencia/lectura. Solo importa `domain` y `paseo_shared`; los
/// puertos de infraestructura genérica se reutilizan desde
/// `application/identity/ports.dart`.
library;

export 'credit_points.dart';
export 'debit_points.dart';
export 'ports.dart';
export 'read_use_cases.dart';
