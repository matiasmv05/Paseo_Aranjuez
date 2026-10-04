import 'package:flutter/material.dart';

/// Átomo para aplicar un efecto sutil de resplandor áurico / brillo animado.
class PaseoShimmer extends StatefulWidget {
  /// Crea un contenedor con barrido de luz metálica.
  const new({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 2500),
  });

  /// Widget contenido que recibe el efecto de destello.
  final Widget child;

  /// Duración de cada ciclo de barrido.
  final Duration duration;

  @override
  State<PaseoShimmer> createState() => _PaseoShimmerState();
}

class _PaseoShimmerState extends State<PaseoShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.5),
              end: const Alignment(1.5, 0.5),
              colors: const [
                Colors.transparent,
                Color(0x33D4AF37),
                Color(0x66F5E6B8),
                Color(0x33D4AF37),
                Colors.transparent,
              ],
              stops: [
                0.0,
                (_controller.value - 0.2).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.2).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
