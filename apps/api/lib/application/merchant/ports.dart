/// Puertos de la capa de aplicacion del panel del comercio (HU-10/11/13).
///
/// Los casos de uso dependen de estas interfaces, no de Postgres ni de
/// HMAC: los adapters (`adapters/out/...`) las implementan (regla 3).
/// Solo se apoyan en tipos de `domain` (regla 3, direccion de dependencia).
library;

import 'package:paseo_api/domain/loyalty/loyalty.dart';

// -------------------------------------------------------------------
// Contexto del personal y cliente
// -------------------------------------------------------------------

/// Rol del personal de comercio; coincide con los roles del JWT (§6).
enum MerchantRole {
  owner('merchant_owner'),
  cashier('merchant_cashier');

  const MerchantRole(this.wire);

  /// Valor del claim `role`.
  final String wire;

  /// Devuelve el rol de [value] o `null` si no es de comercio.
  static MerchantRole? fromWire(String value) {
    for (final role in values) {
      if (role.wire == value) {
        return role;
      }
    }
    return null;
  }
}

/// Contexto del personal autenticado: comercio, sucursal y rol.
///
/// El cajero tiene una sucursal fija (`branchId`); el dueno opera en todas
/// y por eso su [branchId] puede ser `null` (§10.1, FR-017).
final class MerchantContext {
  const MerchantContext({
    required this.establishmentId,
    required this.establishmentName,
    required this.userId,
    required this.role,
    this.branchId,
    this.branchName,
  });

  /// Comercio al que pertenece el llamador.
  final String establishmentId;

  /// Nombre del comercio (para respuestas; nunca PII de cliente).
  final String establishmentName;

  /// Usuario que registra (cajero o dueno).
  final String userId;

  /// Rol verificado.
  final MerchantRole role;

  /// Sucursal fija del cajero; `null` para el dueno.
  final String? branchId;
  final String? branchName;

  /// `true` si es cajero (filtra sus movimientos, FR-019).
  bool get isCashier => role == MerchantRole.cashier;

  /// `true` si es dueno (ve todos los movimientos del comercio).
  bool get isOwner => role == MerchantRole.owner;
}

/// Cliente visto desde el comercio: solo lo necesario para identificar.
///
/// El nombre completo nunca sale en una respuesta: el caso de uso lo
/// enmascara antes de devolverlo (FR-003, §8).
final class CustomerRecord {
  const CustomerRecord({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.phoneVerified,
  });

  final String userId;
  final String fullName;
  final String phone;

  /// Sin telefono verificado no se identifica ni se acredita (§6, §8).
  final bool phoneVerified;
}

// -------------------------------------------------------------------
// Puertos de persistencia
// -------------------------------------------------------------------

abstract interface class EstablishmentRepository {
  /// Contexto de personal del [userId]; `null` si no es staff de ningun
  /// comercio.
  Future<MerchantContext?> findContext(String userId);

  /// Cliente por telefono E.164; `null` si no existe (FR-003).
  Future<CustomerRecord?> findCustomerByPhone(String phone);

  /// Cliente por `user_id` (origen de un token QR, FR-006).
  Future<CustomerRecord?> findCustomerByUserId(String userId);
}

abstract interface class PointsRuleRepository {
  /// Reglas candidatas para (comercio, categoria?) vigentes en [now].
  ///
  /// Devuelve las de alcance `ESTABLISHMENT`, `CATEGORY` y `GLOBAL` sin
  /// resolver: la precedencia y la campana unica las decide
  /// `RuleResolver` en `domain` (§7).
  Future<List<PointsRule>> findApplicableRules({
    required String establishmentId,
    String? categoryId,
    required DateTime now,
  });
}

/// Campo unico de `purchases` que detecto una violacion `23505`.
enum PurchaseUniqueField {
  /// `(establishment_id, idempotency_key)`: reintento de la misma peticion.
  idempotencyKey,

  /// `(establishment_id, invoice_ref)`: factura ya registrada.
  invoiceRef,
}

/// El adapter detecto una violacion de unicidad al insertar la compra.
///
/// El caso de uso la traduce: `idempotencyKey` -> replay 200 y
/// `invoiceRef` -> `DUPLICATE_INVOICE` 409 (§9, FR-016).
final class PurchaseUniqueViolation implements Exception {
  const PurchaseUniqueViolation(this.field);

  final PurchaseUniqueField field;

  @override
  String toString() => 'PurchaseUniqueViolation(${field.name})';
}

abstract interface class PurchaseRepository {
  /// Compra ya registrada con esa clave de idempotencia en el comercio.
  ///
  /// Es el camino de reintento: el caso de uso devuelve 200 con la
  /// respuesta original sin volver a mover el ledger (§9).
  Future<Purchase?> findByIdempotencyKey({
    required String establishmentId,
    required String idempotencyKey,
  });

  /// Compra con esa factura en el comercio; para `DUPLICATE_INVOICE`.
  Future<Purchase?> findByInvoiceRef({
    required String establishmentId,
    required String invoiceRef,
  });

  /// Inserta `purchases` y, si `pointsCredited > 0`, el movimiento
  /// `CREDIT` en `points_ledger` + `audit_log`, en **una transaccion**.
  ///
  /// Nunca escribe `customer_balances`: el trigger mantiene el saldo
  /// (regla 2.3). Lanza [PurchaseUniqueViolation] si choca con un unico.
  Future<Purchase> insert(PurchaseDraft draft);
}

/// Fila cruda de movimiento para la bandeja del comercio.
///
/// [customerName] viene completo de la base; el caso de uso lo enmascara
/// antes de exponerlo (T044, FR-003). [branchId] siempre es del servidor.
final class MovementRecord {
  const MovementRecord({
    required this.id,
    required this.createdAt,
    required this.invoiceRef,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.pointsCredited,
    required this.customerName,
    required this.branchId,
  });

  final String id;
  final DateTime createdAt;
  final String invoiceRef;
  final int grossCents;
  final int discountCents;
  final int netCents;
  final int pointsCredited;
  final String customerName;
  final String branchId;
}

/// Filtro y pagina pedida al repositorio de movimientos.
final class MovementQuery {
  const MovementQuery({
    required this.establishmentId,
    required this.limit,
    this.sellerUserId,
    this.cursor,
  });

  final String establishmentId;

  /// Cajero: solo sus registros. `null` = dueno, ve todo el comercio.
  final String? sellerUserId;

  /// Tamano de pagina ya validado por el caso de uso.
  final int limit;

  /// Cursor opaco de la pagina anterior; `null` = primera pagina.
  final String? cursor;
}

/// Pagina de movimientos con cursor opaco para la siguiente.
final class MovementPageData {
  const MovementPageData({required this.items, this.nextCursor});

  final List<MovementRecord> items;
  final String? nextCursor;
}

abstract interface class MovementRepository {
  /// Movimientos del comercio ordenados `created_at DESC, id DESC`, con
  /// filtro por vendedor cuando [MovementQuery.sellerUserId] no es `null`.
  Future<MovementPageData> list(MovementQuery query);
}

// -------------------------------------------------------------------
// Servicios
// -------------------------------------------------------------------

/// Firma y verifica los tokens de identificacion (HU-10, FR-003/FR-006).
///
/// El ticket de identificacion y el token QR comparten primitiva
/// (HMAC-SHA256) pero no formato ni TTL. `verify*` devuelve `null` cuando la
/// firma es invalida, el token esta vencido o su `kind` no corresponde; el
/// caso de uso traduce ese `null` al `code` del contrato
/// (`INVALID_IDENTIFICATION_TICKET` / `INVALID_QR_TOKEN`, FR-022).
abstract interface class TicketSigner {
  /// Firma un ticket de identificacion ligado al comercio y sucursal.
  String signTicket(IdentificationTicketClaims claims);

  /// Verifica un ticket; `null` si no es valido o esta vencido respecto de
  /// [now].
  IdentificationTicketClaims? verifyTicket(
    String token, {
    required DateTime now,
  });

  /// Firma el token QR de un cliente (lo valida esta feature, no lo emite).
  String signQr(QrTokenClaims claims);

  /// Verifica un token QR; `null` si no es valido o esta vencido respecto de
  /// [now].
  QrTokenClaims? verifyQr(String token, {required DateTime now});
}

/// Accion sujeta a rate limit por comercio (FR-020).
enum MerchantAction {
  preview('preview'),
  registerPurchase('purchase');

  const MerchantAction(this.wire);

  /// Identificador de la accion para telemetria/logs (sin PII).
  final String wire;
}

/// Limite de peticiones por `establishment_id` para `preview`/`purchases`.
abstract interface class RateLimiter {
  /// `false` si se supero el limite de (comercio, accion) -> 429.
  Future<bool> tryAcquire({
    required String establishmentId,
    required MerchantAction action,
  });
}
