import 'dart:io';

import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Soporte para tests de integracion contra el contenedor dev
/// (`paseo-aranjuez-db-1`, expuesto en loopback `DB_DEV_PORT=5433`).
/// SIEMPRE con el rol `paseo_app` (nunca owner ni admin, AGENTS.md §5.2).
///
/// Credenciales: `PASEO_APP_PASSWORD` en entorno, o el valor dev
/// documentado en task-5-report (`dev-app`).
PgConfig integrationConfig() => PgConfig(
  host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
  database: Platform.environment['DB_NAME'] ?? 'paseo',
  user: Platform.environment['DB_USER'] ?? 'paseo_app',
  password: Platform.environment['PASEO_APP_PASSWORD'] ?? 'dev-app',
  port: int.tryParse(Platform.environment['DB_DEV_PORT'] ?? '') ?? 5433,
);

const _uuid = Uuid();

String newId() => _uuid.v4();

/// Correo unico por ejecucion (los tests no limpian la base dev).
String uniqueEmail() => 'it-${_uuid.v4()}@example.com';

/// Telefono boliviano unico (+591 + 8 digitos empezando en 7).
String uniquePhone() {
  final digits = _uuid.v4().replaceAll('-', '').substring(0, 7);
  final numeric = digits.split('').map((c) => c.codeUnitAt(0) % 10).join();
  return '+5917$numeric';
}
