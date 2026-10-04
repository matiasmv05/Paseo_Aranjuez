-- R__seed_dev.sql — Datos de DEMOSTRACIÓN, solo con el override dev (AGENTS.md §5.1).
-- Repeatable e idempotente: todo usa ON CONFLICT DO NOTHING con UUID fijos.
-- Cobertura de la demo de 002 (specs/002-puntos-saldo-catalogo):
--   · 1 cliente demo (verificado) con movimientos (saldo esperado: 150)
--   · 2 establecimientos con sucursales
--   · catálogo: 3 recompensas ACTIVE (PERCENT/FIXED/GIFT), 1 ACTIVE sin stock
--     (available=false) y 1 vencida (no debe listarse) + 1 DRAFT (no lista)
-- El hash de contraseña es un placeholder PHC válido de desarrollo (no vale
-- para iniciar sesión real; el login de demo lo aporta la feature 001 local).
-- NOTA HUT-04: los movimientos entran por INSERT al ledger → el trigger calcula
-- customer_balances; nunca se escribe el saldo a mano.
-- Sin BEGIN/COMMIT: Flyway ya ejecuta cada script en su transacción.

-- ---------------------------------------------------------------------------
-- Cliente demo (identidad mínima; V002)
-- ---------------------------------------------------------------------------
INSERT INTO app.users (id, email, password_hash, role, status, phone_verified, email_verified_at)
VALUES (
    'd0000000-0000-4000-8000-000000000001',
    'cliente.demo@paseo.dev',
    '$argon2id$v=19$m=19456,t=2,p=1$ZGVtby1zYWx0LWRlbm8$ZGVtb2hhc2hkZW1vaGFzaGRlbW8',  -- placeholder dev
    'customer', 'ACTIVE', true, now()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO app.customers (user_id, phone, full_name, phone_verified_at)
VALUES (
    'd0000000-0000-4000-8000-000000000001',
    '+59170000001',
    'Cliente Demo',
    now()
) ON CONFLICT (user_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Establecimientos y sucursales (V004)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Recompensas (V006): 3 canjeables + 1 sin stock + 1 vencida + 1 borrador
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Movimientos de demo (V005): 2 CREDIT + 1 REDEEM → saldo esperado 150.
-- Orden garantizado: INSERTs separados para que el trigger fn_apply_ledger_movement
-- acumule el saldo secuencialmente (multi-row VALUES no garantiza orden del trigger).
-- El trigger rellena balance_after y mantiene customer_balances.
-- ---------------------------------------------------------------------------
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
