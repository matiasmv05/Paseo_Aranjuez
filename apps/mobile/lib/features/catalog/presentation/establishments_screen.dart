import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paseo_mobile/core/error_message.dart';
import 'package:paseo_mobile/core/widgets/status_view.dart';
import 'package:paseo_mobile/features/catalog/application/establishments_controller.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';

/// Pantalla "Comercios" (HU-09): establecimientos adheridos con sus
/// sucursales activas (nombre y dirección).
class EstablishmentsScreen extends StatefulWidget {
  /// La pantalla recibe su [EstablishmentsController] por inyección.
  const new({required this.controller, super.key});

  /// Controlador del estado del listado.
  final EstablishmentsController controller;

  @override
  State<EstablishmentsScreen> createState() => _EstablishmentsScreenState();
}

class _EstablishmentsScreenState extends State<EstablishmentsScreen> {
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
    final establishments = controller.establishments;
    final error = controller.error;
    if (controller.isLoading && establishments == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && establishments == null) {
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
    final items = establishments ?? const <EstablishmentSummary>[];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.storefront,
                message: 'Aún no hay comercios adheridos.',
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
        itemBuilder: (context, index) => Card(
          clipBehavior: Clip.antiAlias,
          child: _EstablishmentTile(establishment: items[index]),
        ),
      ),
    );
  }
}

class _EstablishmentTile extends StatelessWidget {
  const new({required this.establishment});

  final EstablishmentSummary establishment;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.storefront),
      title: Text(establishment.name),
      subtitle: Text(establishment.category),
      children: [
        for (final branch in establishment.branches)
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(branch.name),
            subtitle: Text(branch.address),
          ),
      ],
    );
  }
}
