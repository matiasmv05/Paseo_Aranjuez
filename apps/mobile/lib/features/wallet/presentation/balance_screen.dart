import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paseo_mobile/core/error_message.dart';
import 'package:paseo_mobile/core/format.dart';
import 'package:paseo_mobile/core/widgets/status_view.dart';
import 'package:paseo_mobile/features/wallet/application/balance_controller.dart';

/// Pantalla "Saldo" del cliente (HU-04): puntos disponibles y fecha de la
/// última actualización, con pull-to-refresh.
class BalanceScreen extends StatefulWidget {
  /// La pantalla recibe su [BalanceController] por inyección (los tests
  /// aportan un falso del mismo contrato).
  const new({required this.controller, super.key});

  /// Controlador del estado del saldo.
  final BalanceController controller;

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  Future<void> _reload() => widget.controller.load();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    final balance = controller.balance;
    final error = controller.error;
    if (controller.isLoading && balance == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && balance == null) {
      return StatusView(
        icon: Icons.error_outline,
        message: describeError(error),
        onRetry: _reload,
      );
    }
    if (balance == null) {
      return StatusView(
        icon: Icons.account_balance_wallet_outlined,
        message: 'Aún no tienes puntos.',
        onRetry: _reload,
      );
    }
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Mis puntos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatPoints(balance.balancePoints)} pts',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actualizado: ${formatDateTime(balance.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              describeError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
