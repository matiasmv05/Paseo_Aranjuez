import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:postgres/postgres.dart';

/// `EstablishmentsRepository` sobre `app.establishments` + `app.branches`
/// (V004): lectura del cliente (HU-09, FR-004). Solo activos (sin baja
/// lógica) con sus sucursales `ACTIVE`; nunca expone `max_purchase_cents`
/// ni `compliance_status` (los excluye la proyección SQL, no el Dart).
final class PostgresEstablishmentsRepository
    implements EstablishmentsRepository {
  const PostgresEstablishmentsRepository(this._db);

  final PgDatabase _db;

  @override
  Future<List<EstablishmentRecord>> listActive() async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT e.id::text AS est_id, e.name, e.category, '
        'b.id::text AS br_id, b.name AS br_name, b.address '
        'FROM app.establishments e '
        'LEFT JOIN app.branches b ON b.establishment_id = e.id '
        "  AND b.status = 'ACTIVE' "
        'WHERE e.deleted_at IS NULL '
        'ORDER BY e.name, b.name',
      ),
    );

    final byId = <String, _EstAcc>{};
    final order = <String>[];
    for (final r in result) {
      final row = r.toColumnMap();
      final estId = row['est_id']! as String;
      final acc = byId.putIfAbsent(estId, () {
        order.add(estId);
        return _EstAcc(
          name: row['name']! as String,
          category: row['category']! as String,
        );
      });
      final branchId = row['br_id'] as String?;
      if (branchId != null) {
        acc.branches.add(
          BranchRecord(
            id: branchId,
            name: row['br_name']! as String,
            address: row['address']! as String,
          ),
        );
      }
    }

    return [
      for (final id in order)
        EstablishmentRecord(
          id: id,
          name: byId[id]!.name,
          category: byId[id]!.category,
          branches: byId[id]!.branches,
        ),
    ];
  }
}

final class _EstAcc {
  _EstAcc({required this.name, required this.category});

  final String name;
  final String category;
  final List<BranchRecord> branches = [];
}
