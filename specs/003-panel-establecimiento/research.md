# Research: Panel del Establecimiento

**Feature**: `003-panel-establecimiento` | **Date**: 2026-10-03 | **Spec**: `specs/003-panel-establecimiento/spec.md` | **Plan**: `specs/003-panel-establecimiento/plan.md`

Este documento no redecide nada que ya este cerrado en `AGENTS.md` §15. Registra las decisiones de esta feature, las desviaciones respecto de la constitucion del repo y la deuda que asumimos a cambio.

---

## 1. Donde viven las rutas y que URL ve el cliente

**Decisión.** Las rutas Dart Frog van en `routes/merchant/*.dart` y el cliente las llama con prefijo `/api/v1`.

Esto NO es una contradiccion: son dos niveles distintos.

| Nivel | Artefacto | Resultado |
|-------|-----------|-----------|
| Contrato | `docs/openapi.yaml` con `servers: [{url: /api/v1}]` y paths **relativos** | clave `/merchant/customers/identify` |
| Codigo | `apps/api/routes/merchant/customers/identify.dart` | sirve `/merchant/customers/identify` |
| Borde | `infra/Caddyfile` | `/api/v1/*` -> quita el prefijo -> `api:8080` |

Es exactamente el mismo esquema que ya usa identidad: el contrato declara `/auth/login` como path relativo a `/api/v1`, y el archivo real es `routes/auth/login.dart`. Lo que agregado esta feature son las rutas `routes/merchant/`.

**Hallazgo, y es un bloqueante de alcance.** Hoy el borde no hace el strip. `infra/Caddyfile` tiene:

```
handle /api/* {
    reverse_proxy api:8080
}
```

`reverse_proxy` sin `handle_path` reenvia la ruta intacta, y `apps/api/.dart_frog/server.dart` monta `Router()..mount('/', ...)..mount('/auth', ...)`, sin `/api/v1`. Con eso, `https://<host>/api/v1/auth/login` se reenvia como `/api/v1/auth/login` a un servidor que solo conoce `/auth/login`, y responde 404. El `Path=/api/v1/auth` de la cookie de refresh (§6) y el `servers.url` del contrato son correctos; lo que falta es la pieza que los une.

**Arreglo** (una linea, en el bloque `handle` de ambos sitios de Caddy):

```
handle_path /api/v1/* {
    reverse_proxy api:8080
}
```

`handle_path` a diferencia de `handle` quita el prefijo antes de reenviar. Con eso `/api/v1/auth/login` llega como `/auth/login`.

Arreglo aplicado en `infra/Caddyfile` (prerrequisito 0a del plan), en un snippet `(api)` importado por los dos vhosts para no duplicar:

```
handle_path /api/v1/* {
    reverse_proxy api:8080
}
handle /api {
    respond "Not Found" 404
}
handle /api/* {
    respond "Not Found" 404
}
```

`handle_path` a diferencia de `handle` quita el prefijo antes de reenviar. Con eso `/api/v1/auth/login` llega como `/auth/login`. Los dos `respond 404` evitan que una ruta bajo `/api/` que no existe en el contrato caiga en el `handle` de la SPA y devuelva `index.html` con 200. Hacen falta los dos porque `/api/*` no matchea el `/api` exacto.

### 1.1 Dos defectos preexistentes mas que aparecieron al aplicar el fix

No estaban en el alcance de esta feature, pero aparecieron al probar el archivo de verdad. Los tres se corrigieron juntos en `infra/Caddyfile`.

**(a) `ADMIN_ALLOWED_IPS` vacio impedia que Caddy arrancara.** El vhost 8443 usaba `not remote_ip {$ADMIN_ALLOWED_IPS:""}`, y `remote_ip` no parsea la cadena vacia: `ParseAddr("")`. Como `.env.example` lo deja comentado, `caddy validate` fallaba con el `.env` de ejemplo. El default es `0.0.0.0/0 ::/0`, que matchea cualquier IPv4 e IPv6 y deja pasar a todos cuando la variable no esta. Separado por espacio y no por coma, porque el placeholder se inserta como un token unico y la coma no se reinterpreta como lista.

**(b) El filtro por IP del admin era codigo muerto.** Estaba escrito como `respond @blocked_admin 403`, pero en el orden de directivas de Caddy `respond` se evalua **despues** de `handle` y `handle_path`. Como el `handle` de la SPA capturaba todo, la regla nunca corria: `ADMIN_ALLOWED_IPS` no restringia nada. Ahora es `handle @blocked_admin { respond "Forbidden" 403 }`, que si se evalua, por ir antes que los `handle` del snippet `(api)`.

Ninguno de los dos es codigo de esta feature, asi que no van como tarea de Persona 3; quedan como deuda de infraestructura resuelta. Mencionados aqui porque el segundo era un control de seguridad que no existia en la practica.

### 1.2 Como se verifico

`caddy validate` no alcanza: prueba que el archivo parsea, no que las rutas caigan donde deben. Levanto `caddy:2.11.6-alpine` (la version pineada) con un upstream stub que ecoa `$uri`, y revise las tres rutas en los dos vhosts:

| Peticion | Resultado |
|---|---|
| `/api/v1/auth/login` | 200, el upstream recibe `/auth/login` (prefijo quitado) |
| `/api/v1/merchant/movements` | 200, el upstream recibe `/merchant/movements` |
| `/api/foo` | 404 `Not Found`, no cae en la SPA |
| `/api` y `/api/` | 404 `Not Found` |
| `/` y `/otra/ruta` | 200, `index.html` de la SPA |
| 8443 con `ADMIN_ALLOWED_IPS` no coincidente | 403 en `/api/v1/*`, en `/api/*` y en `/` |
| 8443 con `ADMIN_ALLOWED_IPS` coincidente | 200 (el filtro no sobre-bloquea) |

El `403` llega en el subdominio de administracion completo, no solo en las rutas de API, que era el punto. Nota al reproducir: en Docker Desktop el contenedor ve el IP de origen como el gateway del VM, no como `127.0.0.1`, asi que para probar el caso "permitido" hay que usar la subred del gateway, no `127.0.0.1/32`.

## 2. RLS: deuda asumida, no olvidada

`AGENTS.md` §2 regla 2.7 y §5.3, en su texto original, piden `ENABLE ROW LEVEL SECURITY`, politicas y `infra/tests/rls/<Vxxx>_*.sql` en cada tabla nueva. **Eso esta supersedido desde el 2026-10-03: el MVP se trabaja sin RLS** (regla 2.7, decision de equipo registrada en `docs/agent-audit.md` §BLOCKERS). `V002__identidad.sql` ya esta mergeada bajo esa decision, asi que esta feature no puede reintroducir RLS solo en sus tablas sin desalinear el modelo de seguridad del resto del sistema.

Lo que si se hace, y no es negociable:

- Toda tabla nace con `GRANT` minimo a `paseo_app` y nada mas (§2 regla 2.7, §14).
- Todo `SELECT` de negocio lleva `WHERE establishment_id = $1` con el valor del claim verificado, nunca un id que venga del cliente HTTP. Esto es lo que AGENTS.md §6 exige ("un comercio opera solo sobre su `establishment_id`") y lo que en el MVP hace el trabajo que haria la politica RLS.
- `points_ledger` y `customer_balances` con `REVOKE UPDATE, DELETE, TRUNCATE` para `paseo_app` (§5.3 lo pide para el ledger; aqui se extiende al saldo, que es donde el dinero esta).

**Deuda que se acepta con esto, enunciada para que no se pierda:** con solo `GRANT` a nivel de tabla, un `WHERE` olvidado en un repositorio expone datos de otro comercio. No hay red debajo. Cuando se reintroduzca RLS habra que escribir las politicas de `V004`–`V006` en una migracion nueva (las aplicadas son inmutables, §2 regla 6) y los tests de aislamiento de `infra/tests/rls/`. Es el **GATE 7** de `docs/agent-audit.md`, y sigue bloqueando cualquier despliegue con datos reales.

## 3. Telefono: se relaja el prefijo 6/7

`AGENTS.md` §8 dice "movil de 8 digitos que empieza con 6 o 7" y §15 lo lista como decision **abierta** ("verificacion del plan de numeracion boliviano"). Decision humana de esta feature (2026-10-03): **`+591` seguido de cualquier 8 digitos, sin exigir que empiece con 6 o 7.**

Motivo: el repo no tiene una fuente fiable para esa regla. El unico regex que hay es `apps/api/lib/domain/identity/phone_bo.dart`, que valida longitud y prefijo de pais pero no el primer digito, y no hay documento de la ATT ni del regulador que lo respalde en el repo. Fijar 6/7 sin fuente seria rechazar validos reales por una regla que nadie verifico.

Consecuencias:

- `identify` por telefono acepta cualquier movil boliviano valido. `PHONE_NOT_SUPPORTED` se mantiene para prefijo distinto de `+591`.
- La verificacion por SMS sigue siendo obligatoria: sin `pv=true` no hay ticket de identificacion ni acreditacion (§8).
- `pv=false` (telefono no verificado) mantiene los mismos tres bloqueos de §8: no genera QR, no acredita puntos, no identifica por telefono. Esa parte no se toca.
- `AGENTS.md` §8 y §15 quedan desalineados con esta decision y hay que actualizarlos (§12 obliga a actualizar el archivo cuando se cambia una regla citada).

## 4. `invoice_ref`: obligatorio, y por que es una mejora

`AGENTS.md` §9 dice "`purchases.invoice_ref` es opcional". §15 lo lista como decision abierta ("obligatorio u opcional por comercio"). Decision humana: **obligatorio para todos los comercios.**

Efecto sobre el modelo: el indice unico deja de ser parcial y pasa a ser completo sobre `(establishment_id, invoice_ref)`. Eso no es solo validacion, es la pieza que hace barato el `INSERT ... ON CONFLICT` que traduce el choque a `DUPLICATE_INVOICE` sin una consulta previa, y por lo tanto es lo que permite que la idempotencia y la deteccion de factura repetida ocurran dentro de la misma transaccion (regla 2.4).

Costo asumido: los comercios que hoy cargan compras sin numero de factura tienen que digitarla. Se mitiga con validacion de formato laxa en el borde (1 a 64 caracteres, no vacio tras `btrim`) en lugar de un regex de NIT, porque `AGENTS.md` §10.1 trata la factura como foto + numero + razon social y no define un unico formato de numero. `AGENTS.md` §9 y §15 tambien quedan desalineados.

## 5. Migraciones: por que V004, V005, V006

`V003__cleanup_grants.sql` ya esta aplicado, y §2 regla 6 vuelve inmutable cualquier `V###` en `main`. Editarlo esta prohibido; saltarselo rompe la correlatividad que exige §5.1. Entonces el bloque arranca en `V004` y `V007` en adelante queda libre para Personas 4 y 5.

| Version | Tablas | Por que separada |
|---------|--------|------------------|
| `V004__comercios.sql` | `establishments`, `branches`, `establishment_staff` | Identidad del actor, independiente de la economia de puntos |
| `V005__conversion.sql` | `points_rules` | Persona 4(admin) es quien la escribe; asi su migracion futura puede ampliarla sin tocar las nuestras |
| `V006__compras_y_ledger.sql` | `purchases`, `points_ledger`, `customer_balances` | La unica que mueve saldo |

Las tres son **irreversibles** por decision propia: comercio, compras y ledger son datos de negocio y no se tiran abajo. LosIndices y las columnas que anaden correcciones van en `V007`+, nunca editando estas.

Ninguna lleva RLS (§2 de este documento). Los `GRANT` minimos estan en `data-model.md`, seccion por seccion.

## 6. Datos de desarrollo

`infra/seed/R__seed_dev.sql` ya existe y hoy es un placeholder deliberado (`SELECT 1;`, con nota en `docs/agent-audit.md`). Se **reemplaza** en esta feature; no se crea un archivo nuevo, porque §4 manda los datos de demo ahi y §5.1 exige que sean `R__*.sql`.

El seed es **imprescindible**, no decorativo: §7 deja las reglas exclusivamente en manos de `admin`, y Persona 4 no existe. Sin una fila en `points_rules`, HU-11 y HUT-02 devolverian siempre `NO_APPLICABLE_RULE` y la feature seria indemostrable a mano y sin pruebas de interfaz.

Se parte en dos porque SQL no puede hashear contrasenas:

| Artefacto | Contenido | Por que |
|-----------|-----------|---------|
| `infra/seed/R__seed_dev.sql` | Regla `BASE` GLOBAL activa, regla `CAMPAIGN` inerte (`valid_from` futuro), un comercio de ejemplo | Es lo que SQL expresa sin secretos |
| `apps/api/tool/seed_dev_users.dart` | Los 3 usuarios (dueño, cajero, cliente), fila en `customers`, filas en `establishment_staff` | Reusa el `Argon2idPasswordHasher` de produccion; §14 prohibe otro algoritmo |

`apps/api/tool/` no existe todavia; se crea. Alternativa descartada: hashear en la API. Seria un endpoint de produccion que devuelve credenciales, prohibido por la poltica de este mismo documento.

Las contrasenas de dev son constantes publicas y fijas, y solo existen en la base local. Se listan en `data-model.md`.

## 7. QR: validar sin emitir

Decision humana: PHONE completo mas validacion de QR. **No** se implementa la emision de QR, que es de Persona 1.

El caso de uso `identify` acepta dos metodos y ambos terminan en el mismo estado: un ticket firmado, opaco, ligado a `establishment_id` y `branch_id`, con vida de ~5 minutos. El token de QR se valida con la misma primitiva HMAC, con vida corta (~60 s, `QR_TOKEN_TTL_SECONDS` ya existe en `infra/.env.example`).

**Conflicto real, resuelto asi:** un token con expiracion no puede vivir en un archivo de seed estatico, porque expiraria antes del primer uso. Opciones consideradas:

| Opcion | Veredicto |
|--------|-----------|
| Token estatico en el seed | Descartada: expira y el seed deja de ser reproducible |
| Relajar el TTL en dev | Descartada: el TTL corto es una decision de seguridad (§8) |
| Emitir desde un endpoint de dev | Descartada: endpoint de produccion que devuelve credenciales |
| **Script de seed que emite con el reloj del test** | **Elegida** |

`seed_dev_users.dart` imprime, ademas de las credenciales, un token de ticket y uno de QR ya firmados con `IDENTIFICATION_SECRET`, con el timestamp de emision. Valen para `IDENTIFICATION_TICKET_TTL_SECONDS` y `QR_TOKEN_TTL_SECONDS` respectivamente. En la practica sobreviven unas horas, que es mas que suficiente para una sesion de desarrollo, y el test de `identify` por QR construye su propio token con `Clock` inyectado en vez de depender del impreso.

`IDENTIFICATION_SECRET` es una variable nueva. Va en `infra/.env.example` con valor ficticio, junto a `JWT_SECRET`, y en `INFRASTRUCTURE.md` §7. Es independiente de `JWT_SECRET` a proposito: los tokens de ticket no son sesiones, no llevan claims de usuario y no los emite ni los valida el mismo componente. Rotar uno no debe invalidar sesiones, ni al reves.

## 8. Aritmetica de puntos: entera de punta a punta

§7 fija la formula y §2 regla 9 prohibe `double` para dinero y puntos. La implementacion:

```
puntos_base = redondear(net_cents * points_awarded / amount_per_tier_cents, rule.rounding)
puntos      = redondear(puntos_base  * multiplier_bp  / 10000,                    rule.rounding)
puntos      = min(puntos, max_points_per_purchase)   -- si la regla tiene tope
0           si net_cents < min_purchase_cents         -- si la regla tiene minimo
```

`net_cents`, `amount_per_tier_cents` y `multiplier_bp` son enteros. El unico momento con fraccion es la division, y ahi se aplica el redondeo declarado por la regla **antes** de seguir. En Dart eso es division entera con un desempate explicito, no `/`:

- `FLOOR`: `a ~/ b`
- `CEIL`: `(a + b - 1) ~/ b` con `a >= 0`
- `ROUND`: `((a * 2 + b) ~/ (b * 2))`

Multiplicar por 2 antes de dividir evita el `double` y no desborda: `amount_per_tier_cents` es del orden de miles y `net_cents` de millones, muy por debajo de los 2^62 de un int de Dart en 64 bits.

**Un solo `PointsCalculator`** en `lib/domain/`, compartido por `preview` y por el registro, porque §7 lo exige y porque duplicar el redondeo garantiza que un dia el preview prometa una cantidad y el registro de otra.

`RuleResolver` devuelve **cero**Structs cuando no hay regla aplicable, y el caso de uso tradduce eso a `NO_APPLICABLE_RULE`. Nunca un valor por defecto inventado (§7). El comprobante que recibe el cliente guarda `rule_id`, `campaign_rule_id` y `rule_snapshot` (jsonb), asi una compra de hace meses sigue siendo explicable aunque la regla se haya retirado.

## 9. Alcance del indice de idempotencia

§9 pide que `Idempotency-Key` sea unico y que la misma key devuelva 200 con la respuesta original. `9-stack-tecnologico-paseo-points.md` §9.5 lo dice en singular. El indice es **`(establishment_id, idempotency_key)`**, no solo `idempotency_key`.

Con un indice global, dos comercios distintos que generen la misma key por accidente se rechazan entre si, y el 409 que recibe uno le confirma al otro que esa key ya se uso. Eso es una fuga entre inquilinos, y el aislamiento por comercio es lo unico que sostiene la seguridad de este MVP sin RLS (§2 de este documento). Con el indice compuesto cada comercio es unico dueno de su key, que es exactamente el modelo de la regla 2.4.

La busqueda del reintento ya se hacia con `establishment_id` + `key`, asi que el cambio no altera el flujo: `INSERT ... ON CONFLICT DO NOTHING RETURNING *`, y si no vuelve ninguna fila, `SELECT` por la misma pareja y se responde 200 con el original.

## 10. Frontend: `http` + `flutter_riverpod`

`apps/mobile` hoy solo tiene `flutter` y `very_good_analysis`, y `main_merchant_web.dart` es un stub. Se agregan `http` y `flutter_riverpod`.

- `http` para el cliente REST. `dart:io HttpClient` no compila para web, y el build de comercio es web (`fvm flutter build web -t lib/main_merchant_web.dart`).
- `flutter_riverpod` para el estado. Cuatro pantallas con carga asincrona, un token en memoria y errores tipados: `ChangeNotifier` a mano seria un segundo lenguaje de estado en el repo, y `very_good_analysis` ya lopea patrones estado-en-widget.
- El access token vive **solo en memoria** (§6). Sin `shared_preferences`, sin `localStorage`. El refresh va en la cookie `HttpOnly` que ya define §6, con nombre propio del comercio.
- `paseo_shared` aporta los DTOs y el `ApiErrorCode`. El cliente parsea `application/problem+json` y **programa contra `code`**, nunca contra el texto (§9).
- El target Flutter es `web-merchant` con `main_merchant_web.dart`. El build de administracion (`main_admin_web.dart`) no se toca (§14: no mezclar rutas de comercio y administracion).

## 11. Criterio de seguridad que NO se cumplio

Buscar por nombre parcial esta prohibido (§8). No es una limitacion de la UI: es una superficie de enumeracion de PII. Un `ILIKE '%juan%'` devuelve la existencia de clientes que nunca realizaron una compra en ese comercio. Se implementa coincidencia exacta y con normalizacion (mayusculas, sin tildes) para que `Jose` y `jose` sean el mismo cliente y no dos. La respuesta sigue enmascarando el nombre; lo que se busca por exacto es el apellido y el nombre.

## 12. Claves foraneas diferidas y triggers `SECURITY DEFINER`

Dos decisiones de esquema que no son obvias y conviene tener escritas fuera del SQL.

**`category_id` sin FK.** `establishments.category_id` y `points_rules.category_id` son `uuid` sin clave foranea. El catalogo de categorias es de Persona 4. Con FK, `V004` y `V005` no aplicarian solas, en ese orden, sin fallar, y el bloque entero de migraciones quedaria atado a una feature que todavia no existe. Cuando el catalogo llegue, la FK se agrega en una migracion nueva (`V007`+); las aplicadas son inmutables (§2 regla 6).

Los indices sobre esas columnas si se crean ahora, porque el `RuleResolver` filtra por `category_id` en cada preview.

**Triggers `SECURITY DEFINER`.** Los dos triggers de esta feature (`fn_create_default_branch` y `fn_apply_ledger_to_balance`) son `SECURITY DEFINER`, con `SET search_path = app, pg_temp`.

El motivo es el `GRANT` minimo. Sin `SECURITY DEFINER`, el trigger de la sucursal Principal exigiria `INSERT` sobre `branches` para `paseo_app`, y el del saldo exigiria `UPDATE` sobre `customer_balances`. Las dos cosas contradicen SEC-002 y §2 regla 3 respectivamente: el primero porque abre escritura de tablas de geometria del negocio, el segundo porque la regla dice textual que "el codigo de la API no escribe en `customer_balances`". Con `SECURITY DEFINER` el trigger corre como dueno del esquema y los `GRANT` se quedan en `SELECT`/`INSERT` sobre lo que la feature realmente usa. Es la diferencia entre que la regla se cumpla por convencion o por permiso.

`SET search_path = app, pg_temp` no es decorativo: sin el, una funcion `SECURITY DEFINER` resuelve nombres con el `search_path` de quien la llama, que es el vector clasico de captura de funciones.

**Riesgo residual, asumido a conciencia.** Como `paseo_app` conserva `INSERT` sobre `points_ledger`, en teoria podria mover un saldo con un `delta` negativo. Lo detiene el `CHECK (balance >= 0)`, que aborta la sentencia entera; y el codigo de esta feature solo escribe `CREDIT` con `delta` positivo calculado en el servidor. Aun asi, cuando se reintroduzca RLS hay que revisar que las politicas cubran tambien el `INSERT` en el ledger, no solo el `SELECT`.

**Correccion durante la verificacion desde cero (T013).** El `ON CONFLICT` del trigger de saldo usaba `EXCLUDED.delta`, una columna que no existe en `customer_balances` (`delta` pertenece a `points_ledger`): la migracion fallaba en el primer `INSERT` del ledger. Se corrigio a `EXCLUDED.balance`, que en un upsert es el valor propuesto para la columna `balance` (equivale a `NEW.delta`). El arreglo toca `V006` y el ejemplo SQL de `data-model.md`. Lo detecto recien la aplicacion real desde cero contra PostgreSQL 18; no lo habria visto un test unitario.

## 13. Deuda que queda registrada

| Deuda | Impacto | Quando se paga |
|-------|---------|----------------|
| Sin RLS, sin tests de aislamiento | Un `WHERE` olvidado expone datos de otro comercio | GATE 7, antes de datos reales |
| Filtro por IP del admin inactivo (`respond` despues de `handle`) | `ADMIN_ALLOWED_IPS` no restringia nada | **Resuelto** en `infra/Caddyfile` (§1.1 b) |
| `ADMIN_ALLOWED_IPS` vacio rompia el arranque de Caddy | El vhost 8443 no levantaba con el `.env` de ejemplo | **Resuelto** en `infra/Caddyfile` (§1.1 a) |
| Trigger de saldo `SECURITY DEFINER` | `paseo_app` podria mover saldo con un `delta` negativo | `CHECK (balance >= 0)` lo frena; revisar al reintroducir RLS |
| Sin emision de QR | El comercio no genera el QR, solo lo valida | Persona 1 |
| Sin antifraude | No hay limites ni scores | Persona 4 |
| Sin reembolsos | No hay `REVERSAL` desde la API | Persona 4 |
