import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:postgres/postgres.dart';

/// `BalanceRepository` sobre `app.customer_balances` (V005): solo lectura
/// (el saldo lo escribe exclusivamente el trigger; `paseo_app` no tiene
/// `UPDATE`, AGENTS.md §2 regla 3). Devuelve `null` si el cliente no tiene
/// fila: el caso de uso responde saldo `0` sin crear fila vacía (spec US1.1).
final class PostgresBalanceRepository implements BalanceRepository {
  const PostgresBalanceRepository(this._db);

  final PgDatabase _db;

  @override
  Future<BalanceView?> findByCustomerId(String customerId) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT balance, updated_at FROM app.customer_balances '
        'WHERE customer_id = @c::uuid',
      ),
      parameters: {'c': customerId},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return BalanceView(
      balance: row['balance']! as int,
      updatedAt: row['updated_at']! as DateTime,
    );
  }
}
