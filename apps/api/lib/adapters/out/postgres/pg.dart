import 'dart:io';

import 'package:postgres/postgres.dart';

/// Configuracion de conexion a PostgreSQL (por variables de entorno).
///
/// Variables: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` y `DB_PORT`
/// (por defecto 5432). La API siempre conecta como `paseo_app`
/// (AGENTS.md §5.2).
final class PgConfig {
  const new({
    required this.host,
    required this.database,
    required this.user,
    required this.password,
    this.port = 5432,
  });

  /// Lee el entorno del proceso si no se pasa [environment].
  factory fromEnvironment([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    final user = env['DB_USER'];
    final password = env['DB_PASSWORD'];
    if (user == null || user.isEmpty) {
      throw StateError('DB_USER no definido');
    }
    if (password == null || password.isEmpty) {
      throw StateError('DB_PASSWORD no definido');
    }
    return PgConfig(
      host: env['DB_HOST'] ?? '127.0.0.1',
      database: env['DB_NAME'] ?? 'paseo',
      user: user,
      password: password,
      port: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
    );
  }

  final String host;
  final String database;
  final String user;
  final String password;
  final int port;
}

/// Conexion a la base con sesion transaccional compartida.
///
/// Los repositorios ejecutan sobre [session]: la conexion, o la sesion de
/// la transaccion abierta por `PostgresTransactionRunner`. Asi el caso de
/// uso orquesta atomicidad sin conocer SQL (AGENTS.md §3).
///
/// Wiring pendiente (T031/T033): abrir una instancia en `routes/_middleware.dart`
/// e inyectarla con `provider<PgDatabase>` (el readiness check actual es un
/// stub `( ) async => true`; sustituir por `SELECT 1` sobre esta conexion).
final class PgDatabase {
  new _(this.connection);

  /// Abre la conexion (SSL desactivado: trafico interno compose/loopback).
  static Future<PgDatabase> open(PgConfig config) async {
    final connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.user,
        password: config.password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return PgDatabase._(connection);
  }

  final Connection connection;

  /// Sesion de la transaccion activa (single isolate; dart_frog corre en uno).
  Session? _tx;

  /// Sesion efectiva: la transaccion abierta o la conexion.
  Session get session => _tx ?? connection;

  /// Ejecuta [body] en una transaccion real (BEGIN/COMMIT/ROLLBACK).
  /// Rollback automatico si [body] lanza. Si ya hay una transaccion
  /// activa, la reutiliza (anidacion logica).
  Future<T> runInTransaction<T>(Future<T> Function() body) {
    final active = _tx;
    if (active != null) {
      return body();
    }
    return connection.runTx((tx) async {
      _tx = tx;
      try {
        return await body();
      } finally {
        _tx = null;
      }
    });
  }

  Future<void> close() => connection.close();
}
