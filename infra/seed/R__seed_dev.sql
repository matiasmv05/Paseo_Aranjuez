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

-- ============================================================================
-- 002: Datos de demo para motor de puntos, saldo y catálogo (HU-04..HU-09)
-- ============================================================================
-- Cliente demo de 002 (diferente UUID que el de 003)
INSERT INTO app.users (id, email, password_hash, role, status, phone_verified, email_verified_at)
VALUES (
    'd0000000-0000-4000-8000-000000000001',
    'cliente.demo@paseo.dev',
    '$argon2id$v=19$m=19456,t=2,p=1$ZGVtby1zYWx0LWRlbm8$ZGVtb2hhc2hkZW1vaGFzaGRlbW8',
    'customer', 'ACTIVE', true, now()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO app.customers (user_id, phone, full_name, phone_verified_at)
VALUES (
    'd0000000-0000-4000-8000-000000000001',
    '+59170000001',
    'Cliente Demo',
    now()
) ON CONFLICT (user_id) DO NOTHING;

-- Establecimientos y sucursales para 002 (categorías CAFE/FARMACIA)
INSERT INTO app.establishments (id, name, category)
VALUES
    ('e0000000-0000-4000-8000-000000000001', 'Café Aranjuez',  'CAFE'),
    ('e0000000-0000-4000-8000-000000000002', 'Farmacia Aranjuez', 'FARMACIA')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.branches (id, establishment_id, name, address)
VALUES
    ('b0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', 'Principal', 'Av. Aranjuez 100'),
    ('b0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000001', 'Sucursal Sur', 'Calle Los Pinos 25'),
    ('b0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000002', 'Principal', 'Av. Aranjuez 250')
ON CONFLICT (id) DO NOTHING;

-- Recompensas (V006): 3 canjeables + 1 sin stock + 1 vencida + 1 borrador
INSERT INTO app.rewards (id, establishment_id, name, description, reward_type, value_bp, value_cents, cost_points, stock, valid_from, valid_to, status)
VALUES
    ('a0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001',
     'Café con leche gratis', 'Un café con leche mediano.', 'GIFT', NULL, NULL, 200, 10, now() - interval '1 day', now() + interval '90 days', 'ACTIVE'),
    ('a0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000001',
     'Descuento del 10%', '10% de descuento en tu próxima compra.', 'PERCENT', 1000, NULL, 100, NULL, now() - interval '1 day', now() + interval '90 days', 'ACTIVE'),
    ('a0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000002',
     'Bs 20 de descuento', 'Bs 20 de descuento en compras desde Bs 100.', 'FIXED', NULL, 2000, 300, 5, now() - interval '1 day', now() + interval '90 days', 'ACTIVE'),
    ('a0000000-0000-4000-8000-000000000004', 'e0000000-0000-4000-8000-000000000001',
     'Combo desayuno', 'Combo agotado de la temporada.', 'GIFT', NULL, NULL, 150, 0, now() - interval '1 day', now() + interval '90 days', 'ACTIVE'),
    ('a0000000-0000-4000-8000-000000000005', 'e0000000-0000-4000-8000-000000000002',
     'Promo vencida', 'Ya no vigente: no debe aparecer en el catálogo.', 'PERCENT', 500, NULL, 50, 3, now() - interval '30 days', now() - interval '1 day', 'ACTIVE'),
    ('a0000000-0000-4000-8000-000000000006', 'e0000000-0000-4000-8000-000000000002',
     'Borrador interno', 'Pendiente de aprobación: no debe aparecer.', 'PERCENT', 1000, NULL, 80, 100, now(), now() + interval '90 days', 'DRAFT')
ON CONFLICT (id) DO NOTHING;

-- Movimientos de demo (V005): 2 CREDIT + 1 REDEEM → saldo esperado 150.
INSERT INTO app.purchases (id, establishment_id, branch_id, customer_id, gross_cents, discount_cents, net_cents, invoice_ref, idempotency_key, occurred_at)
VALUES
    ('90000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001',
     'd0000000-0000-4000-8000-000000000001', 12000, 0, 12000, 'FAC-1001', 'seed-purchase-1', now() - interval '3 days'),
    ('90000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000003',
     'd0000000-0000-4000-8000-000000000001', 8000, 0, 8000, 'FAC-2001', 'seed-purchase-2', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.points_ledger (id, customer_id, delta, type, purchase_id, idempotency_key, occurred_at)
VALUES ('70000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001', 120, 'CREDIT',
        '90000000-0000-4000-8000-000000000001', 'seed-credit-1', now() - interval '3 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.points_ledger (id, customer_id, delta, type, purchase_id, idempotency_key, occurred_at)
VALUES ('70000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000001', 80, 'CREDIT',
        '90000000-0000-4000-8000-000000000002', 'seed-credit-2', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.points_ledger (id, customer_id, delta, type, purchase_id, idempotency_key, occurred_at)
VALUES ('70000000-0000-4000-8000-000000000003', 'd0000000-0000-4000-8000-000000000001', -50, 'REDEEM',
        NULL, 'seed-redeem-1', now() - interval '12 hours')
ON CONFLICT (id) DO NOTHING;