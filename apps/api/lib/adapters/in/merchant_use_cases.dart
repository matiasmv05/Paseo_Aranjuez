/// Casos de uso y dependencias del panel del comercio (T071, §3).
///
/// Las rutas reciben [MerchantUseCases] ya construido por el composition
/// root (`di.dart`), igual que [AuthUseCases] en `auth_use_cases.dart`.
library;

import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/application/merchant/use_cases/register_purchase.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Firma de `IdentifyCustomer.call`.
typedef IdentifyFn = Future<contract.IdentifyResult> Function({
  required MerchantContext context,
  required IdentifyInput input,
});

/// Firma de `PreviewPurchase.call`.
typedef PreviewFn = Future<contract.PreviewPurchaseResult> Function({
  required MerchantContext context,
  required contract.PreviewPurchaseRequest request,
});

/// Firma de `RegisterPurchase.call`.
typedef RegisterPurchaseFn = Future<RegisterPurchaseOutcome> Function({
  required MerchantContext context,
  required contract.RegisterPurchaseRequest request,
  required String idempotencyKey,
});

/// Firma de `ListMovements.call`.
typedef ListMovementsFn = Future<contract.MerchantMovementPage> Function({
  required MerchantContext context,
  int? limit,
  String? cursor,
});

/// Casos de uso del panel del comercio visibles para las rutas.
abstract interface class MerchantUseCases {
  /// HU-10: identificar cliente y emitir ticket.
  IdentifyFn get identifyCustomer;

  /// HU-11: previsualizar los puntos de una compra.
  PreviewFn get previewPurchase;

  /// HU-11: registrar la compra y acreditar puntos.
  RegisterPurchaseFn get registerPurchase;

  /// HU-13: listar movimientos del comercio.
  ListMovementsFn get listMovements;
}

/// Une los cuatro casos de uso con los servicios que necesita el middleware
/// de autenticacion (`verifier`, `users`, `establishments`, `rateLimiter`).
///
/// El composition root arma una instancia y la publica como
/// `Future<MerchantDependencies>`; el middleware la consume y provee un
/// [MerchantContext] ya resuelto (T070).
final class MerchantDependencies implements MerchantUseCases {
  /// Crea las dependencias completas del panel.
  const MerchantDependencies({
    required this.identifyCustomer,
    required this.previewPurchase,
    required this.registerPurchase,
    required this.listMovements,
    required this.verifier,
    required this.users,
    required this.establishments,
    required this.rateLimiter,
    required this.clock,
  });

  @override
  final IdentifyFn identifyCustomer;

  @override
  final PreviewFn previewPurchase;

  @override
  final RegisterPurchaseFn registerPurchase;

  @override
  final ListMovementsFn listMovements;

  /// Verifica el access token (HS256) del panel.
  final TokenVerifier verifier;

  /// Relee `status`/`token_version` en `app.users` (claims con 15 min de
  /// desfase, §6).
  final UserRepository users;

  /// Resuelve el [MerchantContext] desde `establishment_staff`.
  final EstablishmentRepository establishments;

  /// Limite de `preview`/`purchases` por comercio (FR-020).
  final RateLimiter rateLimiter;

  /// Reloj del servidor (TTL, ventanas de rate limit).
  final Clock clock;
}
