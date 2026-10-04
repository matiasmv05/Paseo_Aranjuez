import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paseo_mobile/core/error_message.dart';
import 'package:paseo_mobile/core/format.dart';
import 'package:paseo_mobile/core/widgets/status_view.dart';
import 'package:paseo_mobile/features/wallet/application/movements_controller.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';

/// Pantalla "Historial" del cliente (HU-05): movimientos del ledger con
/// scroll infinito por cursor y pull-to-refresh.
class MovementsScreen extends StatefulWidget {
  /// La pantalla recibe su [MovementsController] por inyección.
  const new({required this.controller, super.key});

  /// Controlador paginado del historial.
  final MovementsController controller;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_maybeLoadMore);
    unawaited(widget.controller.refresh());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(widget.controller.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    final items = controller.items;
    final error = controller.error;
    if (controller.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && items.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.error_outline,
                message: describeError(error),
                onRetry: controller.refresh,
              ),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.history,
                message: 'Aún no tienes movimientos.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) return _footer(controller);
          return _MovementTile(movement: items[index]);
        },
      ),
    );
  }

  Widget _footer(MovementsController controller) {
    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = controller.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(describeError(error), textAlign: TextAlign.center),
            TextButton(
              onPressed: controller.loadMore,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!controller.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Fin del historial')),
      );
    }
    return const SizedBox(height: 80);
  }
}

class _MovementTile extends StatelessWidget {
  const new({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final credit = movement.deltaPoints >= 0;
    return ListTile(
      leading: Icon(
        _icon(movement.type),
        color: credit ? colors.primary : colors.error,
      ),
      title: Text(_label(movement.type)),
      subtitle: Text(
        '${formatDateTime(movement.occurredAt)} · '
        'Saldo: ${formatPoints(movement.balanceAfter)}',
      ),
      trailing: Text(
        formatSignedPoints(movement.deltaPoints),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: credit ? colors.primary : colors.error,
        ),
      ),
    );
  }

  static String _label(MovementType type) => switch (type) {
    MovementType.credit => 'Compra',
    MovementType.redeem => 'Canje',
    MovementType.adjust => 'Ajuste',
    MovementType.bonus => 'Bono',
    MovementType.reversal => 'Anulación',
  };

  static IconData _icon(MovementType type) => switch (type) {
    MovementType.credit || MovementType.bonus => Icons.add_circle_outline,
    MovementType.redeem => Icons.card_giftcard,
    MovementType.adjust => Icons.tune,
    MovementType.reversal => Icons.undo,
  };
}
