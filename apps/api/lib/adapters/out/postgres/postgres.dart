/// Adapters de salida PostgreSQL (AGENTS.md §3): unica capa que importa
/// `package:postgres`. El wiring en rutas abre un [PgDatabase] por app y
/// construye repos + [PostgresTransactionRunner] para los casos de uso
/// de identidad y puntos (feature 002).
library;

export 'pg.dart';
export 'pg_errors.dart';
export 'postgres_audit_log_writer.dart';
export 'postgres_balance_repository.dart';
export 'postgres_customer_repository.dart';
export 'postgres_establishment_repository.dart';
export 'postgres_establishments_repository.dart';
export 'postgres_movement_repository.dart';
export 'postgres_movements_repository.dart';
export 'postgres_password_reset_repository.dart';
export 'postgres_points_idempotency_repository.dart';
export 'postgres_points_ledger_repository.dart';
export 'postgres_points_purchase_repository.dart';
export 'postgres_points_rule_repository.dart';
export 'postgres_purchase_repository.dart';
export 'postgres_refresh_token_repository.dart';
export 'postgres_rewards_repository.dart';
export 'postgres_transaction_runner.dart';
export 'postgres_user_repository.dart';
export 'postgres_verification_code_repository.dart';
