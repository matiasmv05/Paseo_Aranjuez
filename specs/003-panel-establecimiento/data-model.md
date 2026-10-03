# Data Model: Panel del Establecimiento

**Feature**: `003-panel-establecimiento` | **Date**: 2026-10-03 | **Spec**: `specs/003-panel-establecimiento/spec.md`

Migraciones nuevas, correlativas y sin saltos. `V003` ya esta aplicado (`V003__cleanup_grants.sql`) y las migraciones aplicadas son inmutables (`AGENTS.md` §2 regla 6), por eso el bloque empieza en `V004`. `V007` en adelante queda libre para Personas 4 y 5.

**Ninguna tabla de este documento lleva RLS.** La regla 2.7 de `AGENTS.md` fue supersedida el 2026-10-03 con "MVP sin RLS" y `V002` ya esta mergeada bajo esa decision. Las tablas nacen con `GRANT` minimo a `paseo_app` y nada mas. El aislamiento multi-comercio se aplica en la capa de aplicacion, filtrando siempre por el `establishment_id` del claim verificado. Ver SEC-002 de la spec y la justificacion en `research.md`.

---

## V004__comercios.sql

### app.establishments

```sql
CREATE TABLE app.establishments (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name               text NOT NULL CHECK (length(btrim(name)) BETWEEN 2 AND 120),
    category_id        uuid,
    address            text,
    city               text,
    status             text NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    max_purchase_cents bigint CHECK (max_purchase_cents IS NULL OR max_purchase_cents > 0),
    compliance_status  text NOT NULL DEFAULT 'ACTIVE'
                       CHECK (compliance_status IN ('ACTIVE', 'OBSERVED', 'SUSPENDED', 'BLOCKED')),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);
```

- `status` es la baja logica. No se borra una fila que tenga compras.
- `category_id` **no** lleva clave foranea a proposito: el catalogo de categorias es de Persona 4 y una FK hacia una tabla que todavia no existe haria fallar a `V004` al aplicarse sola. Cuando exista, se agrega la FK en una migracion nueva.
- `max_purchase_cents` y `compliance_status` los consume el antifraude de Persona 4. Esta feature los lee pero no decide su comportamiento.

### app.branches

```sql
CREATE TABLE app.branches (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id) ON DELETE CASCADE,
    name            text NOT NULL CHECK (length(btrim(name)) BETWEEN 2 AND 120),
    address         text,
    status          text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Clave candidata que permite la FK compuesta de abajo.
CREATE UNIQUE INDEX branches_id_establishment_uk ON app.branches (id, establishment_id);
CREATE INDEX branches_establishment_idx ON app.branches (establishment_id);
```

### Trigger de la sucursal "Principal"

Decision humana del 2026-10-03: todo comercio tiene al menos una sucursal, y no depende de que alguien se acuerde de crearla.

```sql
CREATE FUNCTION app.fn_create_default_branch() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, pg_temp
AS $$
BEGIN
    INSERT INTO app.branches (establishment_id, name, address)
    VALUES (NEW.id, 'Principal', NEW.address);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_establishments_default_branch
    AFTER INSERT ON app.establishments
    FOR EACH ROW EXECUTE FUNCTION app.fn_create_default_branch();
```

`SECURITY DEFINER` es necesario para que `paseo_app` pueda insertar un comercio sin que el trigger exija `INSERT` sobre `branches`: asi los `GRANT` de esta feature pueden quedarse en solo `SELECT`.

### app.establishment_staff

```sql
CREATE TABLE app.establishment_staff (
    establishment_id uuid NOT NULL REFERENCES app.establishments(id) ON DELETE CASCADE,
    user_id          uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    staff_role       text NOT NULL CHECK (staff_role IN ('OWNER', 'CASHIER')),
    branch_id        uuid,
    created_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (establishment_id, user_id),
    CONSTRAINT establishment_staff_branch_role_ck CHECK (
        (staff_role = 'CASHIER' AND branch_id IS NOT NULL) OR
        (staff_role = 'OWNER'   AND branch_id IS NULL)
    ),
    -- La sucursal del cajero tiene que ser de SU propio comercio.
    CONSTRAINT establishment_staff_branch_fk
        FOREIGN KEY (branch_id, establishment_id)
        REFERENCES app.branches (id, establishment_id)
);

CREATE INDEX establishment_staff_user_idx ON app.establishment_staff (user_id);
```

La `CHECK` mas la FK compuesta codifican la regla de `AGENTS.md` §10.1: **el cajero tiene una unica sucursal fija y obligatoria; el dueño no tiene ninguna y opera en todas**. La FK compuesta es lo que impide que un cajero quede asignado a la sucursal de otro comercio.

### GRANTs de V004

```sql
GRANT SELECT ON app.establishments     TO paseo_app;
GRANT SELECT ON app.branches           TO paseo_app;
GRANT SELECT ON app.establishment_staff TO paseo_app;
```

Solo lectura: esta feature no crea comercios ni asigna personal. Cuando Persona 4 agregue el alta de comercios extendera estos `GRANT` con `INSERT`/`UPDATE` en una migracion nueva.

---

## V005__conversion.sql

### app.points_rules

```sql
CREATE TABLE app.points_rules (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scope                   text NOT NULL CHECK (scope IN ('ESTABLISHMENT', 'CATEGORY', 'GLOBAL')),
    type                    text NOT NULL CHECK (type IN ('BASE', 'CAMPAIGN')),
    establishment_id        uuid REFERENCES app.establishments(id) ON DELETE CASCADE,
    category_id             uuid,
    priority                int NOT NULL DEFAULT 100,
    points_awarded          int NOT NULL CHECK (points_awarded > 0),
    amount_per_tier_cents   bigint NOT NULL CHECK (amount_per_tier_cents > 0),
    multiplier_bp           int NOT NULL DEFAULT 10000 CHECK (multiplier_bp >= 0),
    max_points_per_purchase int CHECK (max_points_per_purchase IS NULL OR max_points_per_purchase >= 0),
    min_purchase_cents      bigint NOT NULL DEFAULT 0 CHECK (min_purchase_cents >= 0),
    rounding                text NOT NULL DEFAULT 'FLOOR' CHECK (rounding IN ('FLOOR', 'ROUND', 'CEIL')),
    valid_from              timestamptz NOT NULL DEFAULT now(),
    valid_to                timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT points_rules_scope_target_ck CHECK (
        (scope = 'ESTABLISHMENT' AND establishment_id IS NOT NULL AND category_id IS NULL) OR
        (scope = 'CATEGORY'      AND category_id      IS NOT NULL AND establishment_id IS NULL) OR
        (scope = 'GLOBAL'        AND establishment_id IS NULL     AND category_id IS NULL)
    ),
    CONSTRAINT points_rules_validity_ck CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE INDEX points_rules_active_idx         ON app.points_rules (scope, priority) WHERE valid_to IS NULL;
CREATE INDEX points_rules_establishment_idx ON app.points_rules (establishment_id) WHERE establishment_id IS NOT NULL;
CREATE INDEX points_rules_category_idx      ON app.points_rules (category_id)      WHERE category_id IS NOT NULL;
```

Decisiones de modelado:

- **Una regla activa nunca se edita.** Para cambiarla se inserta una version nueva y a la anterior se le pone `valid_to`. Por eso `valid_to` es nullable y "activa" significa `valid_to IS NULL AND valid_from <= now()`.
- **`multiplicador_bp` esta en basis points**: `10000` es x1 (el valor por defecto, o sea "sin multiplicador"), `20000` es x2. Es un entero, nunca un `double`.
- **`points_awarded` y `amount_per_tier_cents` son enteros positivos**: la aritmetica del calculo es entera de punta a punta (`AGENTS.md` §2 regla 9).
- **Sin columna `version`**: la version es la propia fila mas su `valid_from`. Un indice unico sobre `(scope, establishment_id, category_id, valid_from)` haria explicita la version, pero complica de más para el alcance actual y se deja para cuando una regla deba referenciar a su version anterior.
- `category_id` sin FK, por la misma razon que en `establishments`.

### GRANTs de V005

```sql
GRANT SELECT ON app.points_rules TO paseo_app;
```

**Solo lectura, y es deliberado**: el comercio no tiene ningun endpoint de reglas (`AGENTS.md` §7 y §14). Solo `admin` escribe, y lo hara Persona 4 con su propia migracion que ampliará estos `GRANT`.

---

## V006__compras_y_ledger.sql

### app.customer_balances

```sql
CREATE TABLE app.customer_balances (
    customer_id uuid PRIMARY KEY REFERENCES app.customers(user_id) ON DELETE CASCADE,
    balance     bigint NOT NULL DEFAULT 0 CHECK (balance >= 0),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
```

`CHECK (balance >= 0)` es innegociable (`AGENTS.md` §2 regla 3). La API no escribe aqui: lo hace el trigger.

### app.points_ledger

```sql
CREATE TABLE app.points_ledger (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id        uuid NOT NULL REFERENCES app.customers(user_id),
    establishment_id   uuid REFERENCES app.establishments(id),
    type               text NOT NULL CHECK (type IN ('CREDIT', 'REDEEM', 'ADJUST', 'BONUS', 'REVERSAL')),
    delta              bigint NOT NULL CHECK (delta <> 0),
    purchase_id        uuid,
    redemption_id      uuid,
    reverses_ledger_id uuid REFERENCES app.points_ledger(id),
    reason             text,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT points_ledger_purchase_is_credit_ck CHECK (purchase_id IS NULL OR type = 'CREDIT'),
    CONSTRAINT points_ledger_reversal_target_ck    CHECK ((reverses_ledger_id IS NULL) <> (type = 'REVERSAL'))
);

-- Un solo REVERSAL por credito original.
CREATE UNIQUE INDEX points_ledger_reverses_uk
    ON app.points_ledger (reverses_ledger_id) WHERE reverses_ledger_id IS NOT NULL;
CREATE INDEX points_ledger_customer_idx      ON app.points_ledger (customer_id, created_at DESC);
CREATE INDEX points_ledger_establishment_idx ON app.points_ledger (establishment_id, created_at DESC);
```

- **Ledger de solo insercion.** Nunca `UPDATE`, nunca `DELETE`. Una anulacion es una fila `REVERSAL` que apunta al credito original mediante `reverses_ledger_id`, y el indice unico parcial impide revertir dos veces el mismo credito.
- `redemption_id` queda como `uuid` sin FK: `redemptions` es de Persona 5 y todavia no existe.
- `points_ledger_purchase_is_credit_ck` invierte la regla de `AGENTS.md` §2 regla 2 para esta feature: aqui lo unico que se inserta desde una compra es `CREDIT`. `REDEEM`, `ADJUST`, `BONUS` y `REVERSAL` los escriben otras features.
- El saldo se mantiene con un trigger y **no** con `SELECT ... FOR UPDATE` (`AGENTS.md` §9): el trigger ya serializa.

### Trigger de saldo

```sql
CREATE FUNCTION app.fn_apply_ledger_to_balance() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, pg_temp
AS $$
BEGIN
    INSERT INTO app.customer_balances (customer_id, balance, updated_at)
    VALUES (NEW.customer_id, NEW.delta, now())
    ON CONFLICT (customer_id) DO UPDATE
        SET balance  = app.customer_balances.balance + EXCLUDED.delta,
            updated_at = now();
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_points_ledger_balance
    AFTER INSERT ON app.points_ledger
    FOR EACH ROW EXECUTE FUNCTION app.fn_apply_ledger_to_balance();
```

`SECURITY DEFINER` es lo que permite que `paseo_app` **no** tenga `UPDATE` sobre `customer_balances` y aun asi el saldo se mueva. Es el mecanismo que hace cumplir `AGENTS.md` §2 regla 3 a nivel de permiso, no solo de convencion.

Consecuencia asumida del MVP: como `paseo_app` puede insertar en `points_ledger`, en teoria podria mover saldo con un `delta` negativo. Lo frena el `CHECK (balance >= 0)`, y el codigo de esta feature solo escribe `CREDIT` con `delta` positivo calculado en el servidor. Queda anotado en `research.md` como propiedad conocida del MVP sin RLS.

### app.purchases

```sql
CREATE TABLE app.purchases (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id),
    branch_id        uuid NOT NULL,
    customer_id      uuid NOT NULL REFERENCES app.customers(user_id),
    seller_user_id   uuid NOT NULL REFERENCES app.users(id),
    gross_cents      bigint NOT NULL CHECK (gross_cents >= 0),
    discount_cents   bigint NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    net_cents        bigint NOT NULL CHECK (net_cents >= 0),
    invoice_ref      text NOT NULL CHECK (length(btrim(invoice_ref)) BETWEEN 1 AND 64),
    rule_id          uuid NOT NULL REFERENCES app.points_rules(id),
    campaign_rule_id uuid REFERENCES app.points_rules(id),
    rule_snapshot    jsonb NOT NULL,
    idempotency_key  text NOT NULL CHECK (length(idempotency_key) BETWEEN 8 AND 128),
    points_credited  int NOT NULL DEFAULT 0 CHECK (points_credited >= 0),
    created_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT purchases_amounts_ck CHECK (net_cents = gross_cents - discount_cents),
    CONSTRAINT purchases_branch_fk
        FOREIGN KEY (branch_id, establishment_id)
        REFERENCES app.branches (id, establishment_id)
);

CREATE UNIQUE INDEX purchases_idempotency_uk
    ON app.purchases (establishment_id, idempotency_key);
CREATE UNIQUE INDEX purchases_establishment_invoice_uk
    ON app.purchases (establishment_id, invoice_ref);
CREATE INDEX purchases_establishment_created_idx
    ON app.purchases (establishment_id, created_at DESC, id DESC);
CREATE INDEX purchases_customer_created_idx
    ON app.purchases (customer_id, created_at DESC);
CREATE INDEX purchases_branch_created_idx
    ON app.purchases (branch_id, created_at DESC);
```

Invariantes y por que cada indice existe:

- **`purchases_amounts_ck`** hace que `net_cents` no pueda mentir: si no es `gross - discount`, el `INSERT` revienta con `23514` y la API lo traduce a 422.
- **`invoice_ref` es `NOT NULL`** (decision humana del 2026-10-03), asi que su unicidad es un indice **completo**, no parcial. Acelera el `INSERT ... ON CONFLICT` que traduce el choque a `DUPLICATE_INVOICE` sin una consulta previa.
- **`purchases_idempotency_uk` es sobre `(establishment_id, idempotency_key)`**, no solo sobre `idempotency_key` como decia literalmente el documento 9-stack §9.5. Un indice global obligaria a que dos comercios distintos no pudieran coincidir por accidente en la misma clave, y devolverle un 409 a un comercio por una clave que genero otro seria una fuga de informacion entre inquilinos. Con el indice compuesto cada comercio es Owner of su clave, que es justo el aislamiento que exige `AGENTS.md` §6. Se registra como desviacion en `research.md`.
- **`purchases_establishment_created_idx`** tiene `id DESC` al final para que el cursor de `GET /merchant/movements` sea `(created_at, id)` y ordenado de forma determinista: sin el `id` como desempate, dos compras del mismo timestamp pueden aparecer en cualquier orden entre paginas y el cursor se rompe.
- **`purchases_branch_fk`** garantiza que la sucursal guardada pertenezca al comercio, en la base y no solo en la validacion del use case.
- **`rule_snapshot`** es `NOT NULL` y guarda los parametros de la regla tal como se usaron, para que una compra de hace seis meses siga siendo explicable aunque la regla se haya retirado.

### GRANTs de V006

```sql
GRANT SELECT, INSERT ON app.purchases       TO paseo_app;
GRANT SELECT, INSERT ON app.points_ledger   TO paseo_app;
GRANT SELECT        ON app.customer_balances TO paseo_app;

REVOKE UPDATE, DELETE, TRUNCATE ON app.points_ledger    FROM paseo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON app.customer_balances FROM paseo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON app.purchases       FROM paseo_app;
```

`purchases` tampoco se actualiza ni se borra nunca: una compra dada de baja es una fila `REVERSAL` en el ledger, no un `UPDATE` de la compra (SEC-007). El `SELECT` en `purchases` es lo que permite responder el reintento idempotente con la respuesta original.

---

## Datos de desarrollo

Solo en dev; jamas en produccion. Habilitados por el override `infra/docker-compose.dev.yml` (`AGENTS.md` §5.1). El seed se parte en dos porque SQL no sabe hashear contrasenas (`research.md` §6).

### infra/seed/R__seed_dev.sql

**Este archivo ya existe** y hoy es un placeholder deliberado (`SELECT 1;`, con nota en `docs/agent-audit.md`). Esta feature lo **reemplaza** en el sitio; no se crea un seed nuevo, porque `AGENTS.md` §4 manda los datos de demo ahi y §5.1 exige que sean `R__*.sql`.

Lo que SQL puede expresar sin secretos:

- Una regla `BASE` de alcance `GLOBAL`, activa: `points_awarded = 1`, `amount_per_tier_cents = 10000` (o sea 1 punto por cada 100,00 Bs), `multiplier_bp = 10000`, `rounding = 'FLOOR'`, `min_purchase_cents = 0`.
- Una regla `CAMPAIGN` de alcance `GLOBAL` con `multiplier_bp = 20000` y `valid_from` en el futuro: queda inerte pero permite ver en el panel y en los tests como se comporta una campaña.
- Un comercio de ejemplo con su sucursal "Principal" creada por el trigger.

Es indispensable porque solo `admin` puede crear reglas y Persona 4 no existe: sin esta fila, HU-11 y HUT-02 devolverian siempre `NO_APPLICABLE_RULE` y la feature seria indemostrable.

### apps/api/tool/seed_dev_users.dart

Las contrasenas no se pueden hashear en SQL. Un entrypoint de Dart (directorio `tool/`, nuevo) usa el `Argon2idPasswordHasher` de produccion para crear los tres usuarios de prueba (un `merchant_owner`, un `merchant_cashier` y un `customer` verificado), su fila en `customers`, y los registros de `establishment_staff` que emitiran los claims `est` y `br`. Corre con `fvm dart run tool/seed_dev_users.dart` y solo en dev.

Ademas imprime dos tokens ya firmados con `IDENTIFICATION_SECRET`: uno de ticket de identificacion y uno de QR, ambos con el timestamp de emision, para probar `identify` a mano. No se pueden guardar como constantes porque un token con expiracion (~5 min el ticket, ~60 s el QR, `QR_TOKEN_TTL_SECONDS` en `infra/.env.example`) dejaria de ser valido; la prueba automatizada de QR construye el suyo con `Clock` inyectado en vez de depender del impreso.

CREDenciales de dev, fijas y publicas a proposito (solo existen en la base local):

| Rol | Email | Contrasena |
|-----|-------|-----------|
| `merchant_owner` | `dueno@dev.local` | `Dev-dueno-2026!` |
| `merchant_cashier` | `cajero@dev.local` | `Dev-cajero-2026!` |
| `customer` | `cliente@dev.local` | `Dev-cliente-2026!` |

El cliente se crea con `phone_verified = true` y telefono `+59170000001`, que es el valor que se usa para probar `identify` por `PHONE`.

---

## Resumen de migraciones

| Version | Contenido | Tablas | Reversible |
|---------|-----------|--------|------------|
| `V004__comercios.sql` | Comercios, sucursales, personal, trigger de la sucursal Principal | 3 | No (se corrige con `V007`+) |
| `V005__conversion.sql` | Reglas de conversion versionadas | 1 | No |
| `V006__compras_y_ledger.sql` | Compras, ledger, saldo, trigger de saldo, indices | 3 | No |

Comprobaciones que CI debe seguir levando en verde: migraciones desde cero, `paseo_app` sin `UPDATE`/`DELETE` sobre `points_ledger` ni `UPDATE` sobre `customer_balances`, y `V004`–`V006` inmutables una vez mergeadas.
