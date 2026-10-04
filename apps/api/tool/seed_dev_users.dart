import 'dart:io';

import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/password/argon2id_password_hasher.dart';
import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/domain/loyalty/identification.dart';
import 'package:postgres/postgres.dart';

/// Semilla de usuarios/cliente de desarrollo (T015, solo dev).
///
/// Hashea con `Argon2idPasswordHasher` las tres contrasenas de demo y las
/// escribe en `app.users` (idempotente por UUID), asegura la fila del cliente
/// en `app.customers` y, si estan los datos de T014, imprime un ticket de
/// identificacion y un token QR ya firmados con `IDENTIFICATION_SECRET` y el
/// reloj actual (research.md seccion 7: un token con vencimiento no puede ser
/// una constante de seed).
///
/// No crea comercio, sucursal ni `establishment_staff`: `paseo_app` solo tiene
/// `SELECT` sobre esas tablas (V004). Eso lo aporta `infra/seed/R__seed_dev.sql`
/// cuando corre el servicio `migrate` con el override `dev`.
///
/// Uso (desde `apps/api`, con la BD dev en loopback):
///   SEED_DEV_USERS=1 DB_HOST=127.0.0.1 DB_PORT=5433 DB_NAME=paseo \
///   DB_USER=paseo_app DB_PASSWORD=... IDENTIFICATION_SECRET=... \
///   fvm dart run tool/seed_dev_users.dart
Future<void> main() async {
  final env = Platform.environment;
  if (!_devEnabled(env)) {
    stderr.writeln(
      'seed_dev_users: rechazado. Exporta SEED_DEV_USERS=1 (solo dev).',
    );
    exitCode = 64;
    return;
  }
  final secret = env['IDENTIFICATION_SECRET']?.trim();
  if (secret == null || secret.isEmpty) {
    stderr.writeln(
      'seed_dev_users: falta IDENTIFICATION_SECRET '
      '(el mismo que usa la API).',
    );
    exitCode = 64;
    return;
  }

  final ticketTtl = _ttl(
    env,
    'IDENTIFICATION_TICKET_TTL_SECONDS',
    IdentificationTicketClaims.ttl,
  );
  final qrTtl = _ttl(env, 'QR_TOKEN_TTL_SECONDS', QrTokenClaims.ttl);

  final hasher = Argon2idPasswordHasher();
  final signer = IdentificationSigner(secret: secret);
  const clock = SystemClock();

  PgDatabase? db;
  try {
    db = await PgDatabase.open(PgConfig.fromEnvironment(env));
    for (final demo in _demos) {
      final hash = await hasher.hash(demo.password);
      await _upsertUser(db, demo, hash);
    }
    await _upsertCustomer(db);

    final branchId = await _principalBranchId(db);
    final staff = await _staffCount(db);
    final now = clock.nowUtc();

    final ticket = signer.signTicket(
      IdentificationTicketClaims(
        customerId: _customerId,
        establishmentId: _establishmentId,
        branchId: branchId,
        issuedAt: now,
        expiresAt: now.add(ticketTtl),
      ),
    );
    final qr = signer.signQr(
      QrTokenClaims(
        customerId: _customerId,
        issuedAt: now,
        expiresAt: now.add(qrTtl),
      ),
    );

    _printReport(
      branchId: branchId,
      staffCount: staff,
      ticket: ticket,
      qr: qr,
      now: now,
      ticketTtl: ticketTtl,
      qrTtl: qrTtl,
    );
  } on Object catch (error) {
    stderr.writeln('seed_dev_users: fallo: $error');
    exitCode = 70;
  } finally {
    await db?.close();
  }
}

const _ownerId = '11111111-1111-1111-1111-111111111111';
const _cashierId = '22222222-2222-2222-2222-222222222222';
const _customerId = '33333333-3333-3333-3333-333333333333';
const _establishmentId = 'e0000000-0000-0000-0000-000000000001';
const _customerPhone = '+59170000001';
const _customerName = 'Cliente Demo';
const _guardVariable = 'SEED_DEV_USERS';

/// Usuario de demo: id fijo, correo del seed SQL (T014) y contrasena publica.
final class _DemoUser {
  const _DemoUser({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    required this.label,
  });

  final String id;
  final String email;
  final String password;
  final String role;
  final String label;
}

const _demos = <_DemoUser>[
  _DemoUser(
    id: _ownerId,
    email: 'owner@paseo.dev',
    password: 'Dev-dueno-2026!',
    role: 'merchant_owner',
    label: 'dueno',
  ),
  _DemoUser(
    id: _cashierId,
    email: 'cajero@paseo.dev',
    password: 'Dev-cajero-2026!',
    role: 'merchant_cashier',
    label: 'cajero',
  ),
  _DemoUser(
    id: _customerId,
    email: 'cliente@paseo.dev',
    password: 'Dev-cliente-2026!',
    role: 'customer',
    label: 'cliente',
  ),
];

bool _devEnabled(Map<String, String> env) {
  final value = env[_guardVariable]?.trim().toLowerCase();
  return value == '1' || value == 'true';
}

Duration _ttl(Map<String, String> env, String name, Duration fallback) {
  final seconds = int.tryParse(env[name]?.trim() ?? '');
  if (seconds == null || seconds <= 0) {
    return fallback;
  }
  return Duration(seconds: seconds);
}

Future<void> _upsertUser(
  PgDatabase db,
  _DemoUser demo,
  String passwordHash,
) async {
  await db.session.execute(
    Sql.named(
      'INSERT INTO app.users '
      '(id, email, password_hash, role, status, phone_verified, '
      'email_verified_at, created_at) '
      "VALUES (@id::uuid, @email, @passwordHash, @role, 'ACTIVE', true, "
      'now(), now()) '
      'ON CONFLICT (id) DO UPDATE SET password_hash = EXCLUDED.password_hash',
    ),
    parameters: <String, Object?>{
      'id': demo.id,
      'email': demo.email,
      'passwordHash': passwordHash,
      'role': demo.role,
    },
  );
}

Future<void> _upsertCustomer(PgDatabase db) async {
  await db.session.execute(
    Sql.named(
      'INSERT INTO app.customers '
      '(user_id, phone, full_name, phone_verified_at) '
      'VALUES (@id::uuid, @phone, @name, now()) '
      'ON CONFLICT (user_id) DO UPDATE SET '
      'full_name = EXCLUDED.full_name, '
      'phone_verified_at = '
      'COALESCE(app.customers.phone_verified_at, EXCLUDED.phone_verified_at)',
    ),
    parameters: <String, Object?>{
      'id': _customerId,
      'phone': _customerPhone,
      'name': _customerName,
    },
  );
}

Future<String?> _principalBranchId(PgDatabase db) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT b.id::text AS id FROM app.branches b '
      "WHERE b.establishment_id = @est::uuid AND b.name = 'Principal' "
      'LIMIT 1',
    ),
    parameters: <String, Object?>{'est': _establishmentId},
  );
  if (result.isEmpty) {
    return null;
  }
  return result.first.toColumnMap()['id'] as String?;
}

Future<int> _staffCount(PgDatabase db) async {
  final result = await db.session.execute(
    Sql.named(
      'SELECT count(*)::int AS n FROM app.establishment_staff '
      'WHERE establishment_id = @est::uuid',
    ),
    parameters: <String, Object?>{'est': _establishmentId},
  );
  return result.first.toColumnMap()['n']! as int;
}

void _printReport({
  required String? branchId,
  required int staffCount,
  required String ticket,
  required String qr,
  required DateTime now,
  required Duration ticketTtl,
  required Duration qrTtl,
}) {
  final nowIso = now.toIso8601String();
  print('');
  print('=== Paseo Points - seed de usuarios de desarrollo ===');
  print('Contrasenas rehasheadas con Argon2id; cliente demo asegurado.');
  print('');
  print('Credenciales (solo base local):');
  for (final demo in _demos) {
    print(
      '  ${demo.label.padRight(8)} (${demo.role}) : '
      '${demo.email}  /  ${demo.password}',
    );
  }
  print('');
  print('Comercio demo: $_establishmentId');
  print('Sucursal Principal: ${branchId ?? '(ausente)'}');
  print('');
  print(
    'Ticket de identificacion (cid=$_customerId, est=$_establishmentId, '
    'br=${branchId ?? 'null'}):',
  );
  print('  $ticket');
  print(
    '  emitido $nowIso  vence '
    '${now.add(ticketTtl).toIso8601String()}  (TTL ${ticketTtl.inSeconds}s)',
  );
  print('');
  print('Token QR (cid=$_customerId):');
  print('  $qr');
  print(
    '  emitido $nowIso  vence '
    '${now.add(qrTtl).toIso8601String()}  (TTL ${qrTtl.inSeconds}s)',
  );
  print('');
  if (branchId == null || staffCount == 0) {
    print(
      'ADVERTENCIA: falta el seed dev (R__seed_dev.sql). Corre '
      '`docker compose ... up -d` con el override dev para crear el '
      'comercio, la sucursal Principal y establishment_staff.',
    );
  }
}
