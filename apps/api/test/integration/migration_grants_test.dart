import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late PgDatabase db;

  Future<bool> hasTablePrivilege(String table, String privilege) async {
    final result = await db.session.execute(
      Sql.named(
        'SELECT has_table_privilege(current_user, @table, @privilege) AS ok',
      ),
      parameters: <String, Object?>{'table': table, 'privilege': privilege},
    );
    return result.first.toColumnMap()['ok']! as bool;
  }

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
  });

  tearDownAll(() async {
    await db.close();
  });

  test('T095: los GRANT minimos de paseo_app son los esperados', () async {
    // Ledger de solo insercion (AGENTS.md §5.3, regla 2.2).
    expect(await hasTablePrivilege('app.points_ledger', 'SELECT'), isTrue);
    expect(await hasTablePrivilege('app.points_ledger', 'INSERT'), isTrue);
    expect(await hasTablePrivilege('app.points_ledger', 'UPDATE'), isFalse);
    expect(await hasTablePrivilege('app.points_ledger', 'DELETE'), isFalse);

    // El saldo lo mantiene el trigger: la app no lo escribe (regla 2.3).
    expect(await hasTablePrivilege('app.customer_balances', 'SELECT'), isTrue);
    expect(await hasTablePrivilege('app.customer_balances', 'UPDATE'), isFalse);
    expect(await hasTablePrivilege('app.customer_balances', 'DELETE'), isFalse);

    // Compras: se insertan y consultan, nunca se reescriben.
    expect(await hasTablePrivilege('app.purchases', 'INSERT'), isTrue);
    expect(await hasTablePrivilege('app.purchases', 'UPDATE'), isFalse);
    expect(await hasTablePrivilege('app.purchases', 'DELETE'), isFalse);

    // Comercios y reglas: solo lectura para la app.
    expect(await hasTablePrivilege('app.establishments', 'SELECT'), isTrue);
    expect(await hasTablePrivilege('app.establishments', 'INSERT'), isFalse);
    expect(await hasTablePrivilege('app.points_rules', 'SELECT'), isTrue);
    expect(await hasTablePrivilege('app.points_rules', 'INSERT'), isFalse);

    // Sin DDL desde la aplicacion (AGENTS.md §5.1, §14).
    final schemaCreate = await db.session.execute(
      "SELECT has_schema_privilege(current_user, 'app', 'CREATE') AS ok",
    );
    expect(schemaCreate.first.toColumnMap()['ok'], isFalse);
  });

  test('T095: las escrituras prohibidas fallan con 42501', () async {
    Future<void> expectDenied(String sql) => expectLater(
      db.session.execute(sql),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code.toString(),
          'code',
          '42501',
        ),
      ),
    );

    // `WHERE false`: si el GRANT estuviera mal, la sentencia no toca filas.
    await expectDenied(
      'UPDATE app.points_ledger SET delta = delta WHERE false',
    );
    await expectDenied('DELETE FROM app.points_ledger WHERE false');
    await expectDenied(
      'UPDATE app.customer_balances SET balance = balance WHERE false',
    );
    await expectDenied(
      'UPDATE app.purchases SET gross_cents = gross_cents WHERE false',
    );
  });
}
