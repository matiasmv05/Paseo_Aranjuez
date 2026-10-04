import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paseo_mobile/core/error_message.dart';
import 'package:paseo_mobile/core/format.dart';
import 'package:paseo_mobile/core/widgets/status_view.dart';
import 'package:paseo_mobile/features/catalog/application/rewards_controller.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';

/// Pantalla "Beneficios" (HU-06): catálogo de recompensas canjeables. Las
/// agotadas se muestran marcadas (`available=false`, decisión de la spec 002).
class RewardsScreen extends StatefulWidget {
  /// La pantalla recibe su [RewardsController] por inyección.
  const new({required this.controller, super.key});

  /// Controlador del estado del catálogo.
  final RewardsController controller;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
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
    final rewards = controller.rewards;
    final error = controller.error;
    if (controller.isLoading && rewards == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && rewards == null) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.error_outline,
                message: describeError(error),
                onRetry: _reload,
              ),
            ),
          ],
        ),
      );
    }
    final items = rewards ?? const <RewardSummary>[];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.card_giftcard,
                message: 'No hay beneficios disponibles ahora.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _RewardCard(reward: items[index]),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const new({required this.reward});

  final RewardSummary reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: reward.available ? 1 : 0.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reward.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${formatPoints(reward.costPoints)} puntos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(reward.description),
              if (reward.validTo != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Válido hasta ${formatDate(reward.validTo!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(_typeLabel(reward.type)),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (!reward.available)
                    Chip(
                      label: const Text('Agotado'),
                      labelStyle: TextStyle(color: theme.colorScheme.error),
                      visualDensity: VisualDensity.compact,
                    )
                  else if (reward.stock != null)
                    Chip(
                      label: Text('Quedan ${reward.stock}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(RewardType type) => switch (type) {
    RewardType.percent => 'Descuento %',
    RewardType.fixed => 'Descuento fijo',
    RewardType.gift => 'Regalo',
  };
}
