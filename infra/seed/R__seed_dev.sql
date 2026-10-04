-- R__seed_dev.sql — Datos de DEMOSTRACIÓN, solo con el override dev (AGENTS.md §5.1).
-- Repeatable: Flyway lo reaplica cuando cambia su checksum, así que este archivo
-- debe ser idempotente (UUIDs fijos + ON CONFLICT DO NOTHING). NUNCA corre en
-- producción: el servicio `migrate` sin el override dev no monta /flyway/seed.
--
-- Los usuarios se crean con un password_hash centinela NO autenticable; el tool
-- `apps/api/tool/seed_dev_users.dart` (T015) escribe el Argon2id real y emite los
-- tokens de prueba. Este seed por sí solo no habilita login.
--
-- IDs fijos:
--   comercio      e0000000-0000-0000-0000-000000000001
--   owner         11111111-1111-1111-1111-111111111111
--   cajero        22222222-2222-2222-2222-222222222222
--   cliente       33333333-3333-3333-3333-333333333333
--   regla GLOBAL  f0000000-0000-0000-0000-000000000001

-- ============================================================================
-- Usuarios (verificados: teléfono y correo)
-- ============================================================================
INSERT INTO app.users (id, email, password_hash, role, status, phone_verified, email_verified_at, created_at)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'owner@paseo.dev',   '!seed-dev-placeholder', 'merchant_owner',   'ACTIVE', true, now(), now()),
    ('22222222-2222-2222-2222-222222222222', 'cajero@paseo.dev',  '!seed-dev-placeholder', 'merchant_cashier', 'ACTIVE', true, now(), now()),
    ('33333333-3333-3333-3333-333333333333', 'cliente@paseo.dev', '!seed-dev-placeholder', 'customer',         'ACTIVE', true, now(), now())
ON CONFLICT (id) DO NOTHING;

-- Solo el cliente tiene perfil en customers (ahí vive el teléfono, V002).
INSERT INTO app.customers (user_id, phone, full_name, phone_verified_at)
VALUES ('33333333-3333-3333-3333-333333333333', '+59170000001', 'Cliente Demo', now())
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- Comercio demo (el trigger de V004 crea la sucursal "Principal")
-- ============================================================================
INSERT INTO app.establishments (id, name, address, city, status, compliance_status)
VALUES ('e0000000-0000-0000-0000-000000000001', 'Comercio Demo', 'Av. Demo 123 #45', 'La Paz', 'ACTIVE', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- Personal: el dueño opera en todas las sucursales (branch_id NULL); el cajero
-- queda fijo en "Principal" (CHECK de V004 + decisión AGENTS.md §15).
INSERT INTO app.establishment_staff (establishment_id, user_id, staff_role, branch_id)
VALUES ('e0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'OWNER', NULL)
ON CONFLICT (establishment_id, user_id) DO NOTHING;

INSERT INTO app.establishment_staff (establishment_id, user_id, staff_role, branch_id)
SELECT 'e0000000-0000-0000-0000-000000000001',
       '22222222-2222-2222-2222-222222222222',
       'CASHIER',
       b.id
FROM app.branches b
WHERE b.establishment_id = 'e0000000-0000-0000-0000-000000000001'
  AND b.name = 'Principal'
ON CONFLICT (establishment_id, user_id) DO NOTHING;

-- ============================================================================
-- Regla de conversión GLOBAL BASE activa
-- ============================================================================
-- 10 puntos por cada 100,00 Bs (10000 centavos), sin tope ni compra mínima,
-- redondeo FLOOR. Es la BASE que resuelve el RuleResolver cuando no hay regla
-- de comercio/categoría (precedencia ESTABLISHMENT > CATEGORY > GLOBAL).
INSERT INTO app.points_rules (
    id, scope, type, establishment_id, category_id, priority,
    points_awarded, amount_per_tier_cents, multiplier_bp,
    max_points_per_purchase, min_purchase_cents, rounding, valid_from
)
VALUES (
    'f0000000-0000-0000-0000-000000000001', 'GLOBAL', 'BASE', NULL, NULL, 100,
    10, 10000, 10000,
    NULL, 0, 'FLOOR', now()
)
ON CONFLICT (id) DO NOTHING;
