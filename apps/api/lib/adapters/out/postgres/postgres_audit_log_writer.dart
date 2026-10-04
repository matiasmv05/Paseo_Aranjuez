import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:postgres/postgres.dart';

/// `AuditLogWriter` sobre `app.audit_log` (regla 2.4; FR-011): solo INSERT
/// (revocado UPDATE/DELETE a `paseo_app`). Sin datos personales: el caso de
/// uso decide los campos; aqui solo se persiste.
final class PostgresAuditLogWriter implements AuditLogWriter {
  const new(this._db);

  final PgDatabase _db;

  @override
  Future<void> write({
    required String action,
    required String entityType,
    String? entityId,
    String? userId,
    String role = 'system',
  }) async {
    await _db.session.execute(
      Sql.named(
        'INSERT INTO app.audit_log '
        '(actor_role, actor_user_id, action, entity, entity_id) VALUES '
        '(@role, @userId::uuid, @action, @entity, @entityId)',
      ),
      parameters: <String, Object?>{
        'role': role,
        'userId': userId,
        'action': action,
        'entity': entityType,
        'entityId': entityId,
      },
    );
  }
}
