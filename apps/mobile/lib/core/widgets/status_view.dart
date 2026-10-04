import 'package:flutter/material.dart';

/// Vista común de estado vacío o de error: icono, mensaje y botón de
/// reintento opcional. Reutilizada por las cuatro pantallas del cliente
/// (estados loading/success/empty/error, F7 de la feature 002).
class StatusView extends StatelessWidget {
  /// Crea la vista con [icon] y [message]; [onRetry] habilita el botón
  /// "Reintentar".
  const new({
    required this.icon,
    required this.message,
    this.onRetry,
    super.key,
  });

  /// Icono central del estado.
  final IconData icon;

  /// Mensaje para el usuario.
  final String message;

  /// Acción de reintento; `null` oculta el botón.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
