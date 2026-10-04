import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/admin_tab_pill.dart';
import 'package:paseo_mobile/design_system/molecules/admin_chart_tooltip.dart';
import 'package:paseo_mobile/design_system/molecules/admin_insight_item.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Modelo de datos para un punto diario del gráfico analítico.
class ChartDataPoint {
  /// Crea un punto de datos con día, fecha y puntos emitidos.
  const new({
    required this.dayLabel,
    required this.dateLabel,
    required this.points,
    this.badgeText,
    this.isToday = false,
  });

  /// Día de la semana (e.g. 'Mon', 'Fri', 'Sun (Today)').
  final String dayLabel;

  /// Fecha del mes (e.g. 'Oct 18', 'Oct 22').
  final String dateLabel;

  /// Cantidad de puntos registrada.
  final double points;

  /// Insignia especial (e.g. 'PEAK RECORD').
  final String? badgeText;

  /// Si corresponde al día de hoy.
  final bool isToday;
}

/// Gráfico spline interactivo de actividad de transacciones del ledger
/// (Organismo).
class AdminTransactionChart extends StatefulWidget {
  /// Crea el componente de análisis transaccional con curva spline y tooltip
  /// interactivo.
  const new({this.initialRangeIndex = 0, this.onRangeChanged, super.key});

  /// Índice inicial de rango (0 = 7 días, 1 = 30 días).
  final int initialRangeIndex;

  /// Callback al conmutar el rango de días.
  final ValueChanged<int>? onRangeChanged;

  @override
  State<AdminTransactionChart> createState() => _AdminTransactionChartState();
}

class _AdminTransactionChartState extends State<AdminTransactionChart>
    with SingleTickerProviderStateMixin {
  late int _selectedRangeIndex;
  late int _selectedIndex;
  late AnimationController _animController;
  late Animation<double> _curveAnimation;

  // Datos reales del MVP para los últimos 7 días
  static const List<ChartDataPoint> _last7DaysData = [
    ChartDataPoint(dayLabel: 'Mon', dateLabel: 'Oct 18', points: 26000),
    ChartDataPoint(dayLabel: 'Tue', dateLabel: 'Oct 19', points: 38000),
    ChartDataPoint(dayLabel: 'Wed', dateLabel: 'Oct 20', points: 32500),
    ChartDataPoint(dayLabel: 'Thu', dateLabel: 'Oct 21', points: 45000),
    ChartDataPoint(
      dayLabel: 'Fri',
      dateLabel: 'Oct 22',
      points: 56800,
      badgeText: 'PEAK RECORD',
    ),
    ChartDataPoint(dayLabel: 'Sat', dateLabel: 'Oct 23', points: 42000),
    ChartDataPoint(
      dayLabel: 'Sun (Today)',
      dateLabel: 'Oct 24',
      points: 48290,
      isToday: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRangeIndex = widget.initialRangeIndex;
    _selectedIndex = 4; // Por defecto seleccionado Viernes 22 (Peak Record)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _curveAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchRange(int index) {
    if (_selectedRangeIndex == index) return;
    setState(() {
      _selectedRangeIndex = index;
      if (index == 0) {
        _selectedIndex = 4;
      }
    });
    _animController
      ..reset()
      ..forward();
    widget.onRangeChanged?.call(index);
  }

  void _selectDay(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const activeData = _last7DaysData;
    final selectedPoint = activeData[_selectedIndex];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF202230)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con título, métricas de pico/promedio y conmutador
          _buildHeader(),
          const SizedBox(height: 28),

          // 2. Gráfico interactivo con curva Spline y Tooltip dinámico
          AnimatedBuilder(
            animation: _curveAnimation,
            builder: (context, child) {
              return _buildChartCanvas(activeData, selectedPoint);
            },
          ),
          const SizedBox(height: 24),

          // 3. Divisor sutil
          const Divider(color: Color(0xFF1B1D28), thickness: 0.8, height: 1),
          const SizedBox(height: 20),

          // 4. Pie con perspectivas analíticas (Highest Volume, Peak Window,
          // POS Sync)
          _buildFooterInsights(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 780;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Recent Transaction Activity',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: PaseoColors.textWhite,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Text(
                    'VERIFIED LEDGER',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Aggregated points minted, claimed, and reconciled via '
              'estate NFC terminals.',
              style: TextStyle(fontSize: 12, color: Color(0xFF787B8A)),
            ),
          ],
        );

        final controlsBlock = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Métrica de Pico
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PEAK',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF787B8A),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '68,400',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PTS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 20),

            // Métrica de Promedio
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AVERAGE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF787B8A),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '42,150',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PTS/day',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Selector conmutador de rango temporal
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF141620),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF262838)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminTabPill(
                    label: 'LAST 7 DAYS',
                    isSelected: _selectedRangeIndex == 0,
                    onTap: () => _switchRange(0),
                  ),
                  AdminTabPill(
                    label: 'LAST 30 DAYS',
                    isSelected: _selectedRangeIndex == 1,
                    onTap: () => _switchRange(1),
                  ),
                ],
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              controlsBlock,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: controlsBlock,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCanvas(
    List<ChartDataPoint> data,
    ChartDataPoint selectedPoint,
  ) {
    return SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth;
          const chartHeight = 250.0;
          const leftPadding = 42.0;
          final availableWidth = chartWidth - leftPadding - 16;
          final stepX = availableWidth / (data.length - 1);

          final selectedX = leftPadding + (_selectedIndex * stepX);
          const maxVal = 70000.0;
          final normalizedY =
              (selectedPoint.points * _curveAnimation.value) / maxVal;
          final selectedY = chartHeight - (normalizedY * (chartHeight - 30));

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Eje Y y líneas de fondo
              _buildYAxisLabels(chartHeight),

              // 2. Línea vertical discontinua hacia el nodo seleccionado
              Positioned(
                left: selectedX,
                top: selectedY,
                bottom: 50,
                child: CustomPaint(
                  painter: _DashedLinePainter(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                ),
              ),

              // 3. Pintor de área spline dorada
              Positioned(
                left: leftPadding,
                top: 0,
                width: availableWidth,
                height: chartHeight,
                child: CustomPaint(
                  painter: _SplineChartPainter(
                    data: data,
                    progress: _curveAnimation.value,
                    maxVal: maxVal,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),

              // 4. Tooltip flotante posicionado sobre el punto seleccionado
              Positioned(
                left: (selectedX - 75).clamp(10.0, chartWidth - 160.0),
                top: (selectedY - 68).clamp(0.0, chartHeight),
                child: AdminChartTooltip(
                  dateLabel: selectedPoint.dateLabel.toUpperCase(),
                  pointsValue:
                      '${_formatPoints(selectedPoint.points.toInt())} '
                      'PTS issued',
                  badgeText: selectedPoint.badgeText ?? 'RECORD',
                ),
              ),

              // 5. Etiquetas del Eje X y detectores táctiles/hover para cada día
              Positioned(
                left: leftPadding,
                bottom: 0,
                width: availableWidth,
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(data.length, (index) {
                    final item = data[index];
                    final isCurrent = index == _selectedIndex;

                    return Expanded(
                      child: InkWell(
                        onTap: () => _selectDay(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.dayLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? const Color(0xFFE5C07B)
                                    : const Color(0xFF8A8D9E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.dateLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isCurrent
                                    ? const Color(0xFFE5C07B)
                                    : const Color(0xFF5B5D6D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYAxisLabels(double height) {
    const labels = ['70k', '50k', '35k', '20k', '0k'];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: labels.map((label) {
          return Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4C4E5E),
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 0.6, color: const Color(0xFF191B24)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooterInsights() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        const item1 = AdminInsightItem(
          icon: Icons.watch_outlined,
          subtitle: 'HIGHEST VOLUME BOUTIQUE',
          title: 'Haute Horlogerie',
          highlightText: ' (32%)',
        );

        const item2 = AdminInsightItem(
          icon: Icons.access_time_rounded,
          subtitle: 'PEAK ACTIVITY WINDOW',
          title: '18:00 – 21:00 CEST',
        );

        const item3 = AdminInsightItem(
          icon: Icons.cloud_done_outlined,
          subtitle: 'SETTLEMENT STATUS',
          title: 'All POS Synced',
          dotColor: Color(0xFFE5C07B),
        );

        if (isWide) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: item1),
              Expanded(child: item2),
              Expanded(child: item3),
            ],
          );
        }

        return const Wrap(
          runSpacing: 14,
          spacing: 20,
          children: [item1, item2, item3],
        );
      },
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0.0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplineChartPainter extends CustomPainter {
  const new({
    required this.data,
    required this.progress,
    required this.maxVal,
    required this.selectedIndex,
  });

  final List<ChartDataPoint> data;
  final double progress;
  final double maxVal;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i].points * progress) / maxVal;
      final y = height - (normalized * (height - 30));
      points.add(Offset(x, y));
    }

    final splinePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // Cálculo de curvas Bézier cúbicas suaves (Catmull-Rom a Bézier)
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      splinePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // 1. Degradado dorado bajo el área
    final areaPath = Path.from(splinePath)
      ..lineTo(points.last.dx, height)
      ..lineTo(points.first.dx, height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE5C07B).withValues(alpha: 0.22),
          const Color(0xFFE5C07B).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // 2. Trazo spline dorado
    final strokePaint = Paint()
      ..color = const Color(0xFFE5C07B)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(splinePath, strokePaint);

    // 3. Nodos circulares
    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;

      if (isSelected) {
        // Halo exterior resplandeciente
        canvas.drawCircle(
          pt,
          8,
          Paint()
            ..color = const Color(0xFFE5C07B).withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
      }

      // Nodo base y centro oscuro
      canvas
        ..drawCircle(
          pt,
          isSelected ? 4.5 : 3,
          Paint()
            ..color = const Color(0xFFE5C07B)
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          pt,
          isSelected ? 2.5 : 1.5,
          Paint()
            ..color = const Color(0xFF10121A)
            ..style = PaintingStyle.fill,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}
