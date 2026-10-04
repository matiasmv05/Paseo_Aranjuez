/// HU-13 (US4): bandeja de movimientos del comercio (FR-019).
///
/// El cajero solo ve sus registros; el dueno ve todo el comercio. El nombre
/// del cliente se expone enmascarado (FR-003). Orden
/// `created_at DESC, id DESC` con paginacion por cursor.
library;

import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Devuelve una pagina de movimientos ya lista para el contrato.
final class ListMovements {
  /// Crea el caso de uso.
  const ListMovements({required MovementRepository movements})
    : _movements = movements;

  /// Tamano de pagina por defecto si no se pide `limit`.
  static const defaultLimit = 20;

  /// Limite minimo aceptado por el contrato.
  static const minLimit = 1;

  /// Limite maximo aceptado por el contrato.
  static const maxLimit = 100;

  final MovementRepository _movements;

  /// Lista los movimientos visibles para [context].
  Future<contract.MerchantMovementPage> call({
    required MerchantContext context,
    int? limit,
    String? cursor,
  }) async {
    final page = await _movements.list(
      MovementQuery(
        establishmentId: context.establishmentId,
        sellerUserId: context.isCashier ? context.userId : null,
        limit: _validateLimit(limit),
        cursor: cursor,
      ),
    );
    return contract.MerchantMovementPage(
      items: [
        for (final record in page.items)
          contract.MerchantMovement(
            id: record.id,
            createdAt: record.createdAt,
            invoiceRef: record.invoiceRef,
            grossCents: record.grossCents,
            discountCents: record.discountCents,
            netCents: record.netCents,
            pointsCredited: record.pointsCredited,
            customerName: maskCustomerName(record.customerName),
            branchId: record.branchId,
          ),
      ],
      nextCursor: page.nextCursor,
    );
  }

  int _validateLimit(int? limit) {
    if (limit == null) {
      return defaultLimit;
    }
    if (limit < minLimit || limit > maxLimit) {
      throw LoyaltyException.validation(
        'limit debe estar entre $minLimit y $maxLimit',
      );
    }
    return limit;
  }
}
