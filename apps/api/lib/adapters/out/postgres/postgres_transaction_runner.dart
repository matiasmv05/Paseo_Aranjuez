import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/identity/ports.dart';

/// `TransactionRunner` Postgres (T030). Abre la transaccion y ejecuta
/// el cuerpo dentro; commit/rollback reales.
final class PostgresTransactionRunner implements TransactionRunner {
  const new(this._db);

  final PgDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() body) => _db.runInTransaction(body);
}
