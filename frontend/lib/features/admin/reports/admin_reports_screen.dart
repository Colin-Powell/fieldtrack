import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/admin_reports_provider.dart';
import 'utils/pdf_export_utils.dart';

class _C {
  static const bg = Color(0xFFF3F4F6);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 24.0;
}

class TrendDataPoint {
  final String label;
  final double value;
  final String dateLabel;

  const TrendDataPoint({
    required this.label,
    required this.value,
    required this.dateLabel,
  });
}

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _reportGenerated = false;
  int? _hoveredBarIndex;

  void _updateHoverIndex(Offset pos, double containerWidth, int dataLength) {
    if (dataLength == 0) return;
    const leftPadding = 36.0;
    final chartWidth = containerWidth - leftPadding;
    if (chartWidth <= 0) return;

    final barWidth = min(54.0, (chartWidth / dataLength) * 0.6);
    final spacing =
        (chartWidth - (barWidth * dataLength)) / max(1, dataLength - 1);

    for (int i = 0; i < dataLength; i++) {
      final xStart = leftPadding + i * (barWidth + spacing);
      final xEnd = xStart + barWidth;

      if (pos.dx >= xStart - (spacing / 2) && pos.dx <= xEnd + (spacing / 2)) {
        if (_hoveredBarIndex != i) setState(() => _hoveredBarIndex = i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsyncValue = ref.watch(adminReportsProvider);
    final filters = ref.watch(adminReportFiltersProvider);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate System Reports',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),

          // Filters Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: reportAsyncValue.when(
              data: (data) {
                final filterData = data['filters'] ?? {};
                final periods = [
                  'This Week',
                  'This Month',
                  'This Quarter',
                  'This Year',
                  'All Time',
                ];
                final departments = List<String>.from(
                  filterData['departments'] ?? ['All Departments'],
                );
                final supervisors = List<Map<String, dynamic>>.from(
                  filterData['supervisors'] ??
                      [
                        {'id': 'All Supervisors', 'name': 'All Supervisors'},
                      ],
                );
                final counties = List<String>.from(
                  filterData['counties'] ?? ['All Counties'],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Parameters',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Date Range',
                            filters.period,
                            periods,
                            (val) =>
                                ref
                                    .read(adminReportFiltersProvider.notifier)
                                    .state = filters.copyWith(
                                  period: val,
                                ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'Department',
                            filters.department,
                            departments,
                            (val) =>
                                ref
                                    .read(adminReportFiltersProvider.notifier)
                                    .state = filters.copyWith(
                                  department: val,
                                ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'Supervisor',
                            filters.supervisorId,
                            supervisors.map((s) => s['id'] as String).toList(),
                            (val) =>
                                ref
                                    .read(adminReportFiltersProvider.notifier)
                                    .state = filters.copyWith(
                                  supervisorId: val,
                                ),
                            displayItems: supervisors
                                .map((s) => s['name'] as String)
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'County',
                            filters.county,
                            counties,
                            (val) =>
                                ref
                                    .read(adminReportFiltersProvider.notifier)
                                    .state = filters.copyWith(
                                  county: val,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            ref
                                    .read(adminReportFiltersProvider.notifier)
                                    .state =
                                AdminReportFilters();
                            setState(() {
                              _reportGenerated = false;
                            });
                          },
                          icon: Icon(
                            PhosphorIcons.arrowCounterClockwise(),
                            size: 18,
                          ),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _reportGenerated = true;
                            });
                          },
                          icon: Icon(PhosphorIcons.chartBar(), size: 18),
                          label: const Text('Generate Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1BA654),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),

          const SizedBox(height: 48),

          // Generated Report Result
          if (_reportGenerated)
            reportAsyncValue.when(
              data: (data) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Report Results',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await PdfExportUtils.generateAndDownloadReport(
                                data,
                              );
                            },
                            icon: Icon(
                              PhosphorIcons.downloadSimple(),
                              size: 18,
                            ),
                            label: const Text('Export PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1BA654),
                              side: const BorderSide(color: Color(0xFF1BA654)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildChartCard(
                                title: 'Activity Trend (${filters.period})',
                                child: _buildActivityLineChart(
                                  data['trendData'] as List<dynamic>? ?? [],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildChartCard(
                                title: 'County Distribution',
                                child: _buildCountyPieChart(
                                  data['countyDistribution']
                                          as Map<String, dynamic>? ??
                                      {},
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) =>
                  Expanded(child: Center(child: Text('Error: $err'))),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    List<String>? displayItems,
  }) {
    if (!items.contains(value) && items.isNotEmpty) {
      value = items.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: List.generate(items.length, (index) {
                return DropdownMenuItem(
                  value: items[index],
                  child: Text(
                    displayItems != null ? displayItems[index] : items[index],
                    style: const TextStyle(fontFamily: 'Inter'),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: onChanged,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: const Color(0xFF9CA3AF),
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildActivityLineChart(List<dynamic> rawTrendData) {
    if (rawTrendData.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
        ),
      );
    }

    final trendData = rawTrendData
        .map(
          (t) => TrendDataPoint(
            label: t['label'] ?? '',
            value: (t['value'] as num).toDouble(),
            dateLabel: t['dateLabel'] ?? '',
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _updateHoverIndex(
            e.localPosition,
            constraints.maxWidth,
            trendData.length,
          ),
          onExit: (_) => setState(() => _hoveredBarIndex = null),
          child: GestureDetector(
            onTapDown: (e) => _updateHoverIndex(
              e.localPosition,
              constraints.maxWidth,
              trendData.length,
            ),
            onPanUpdate: (e) => _updateHoverIndex(
              e.localPosition,
              constraints.maxWidth,
              trendData.length,
            ),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: _BarChartPainter(
                  dataPoints: trendData,
                  activeIndex: _hoveredBarIndex,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountyPieChart(Map<String, dynamic> countyDistribution) {
    if (countyDistribution.isEmpty) {
      return const Center(
        child: Text(
          'No distribution data',
          style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
        ),
      );
    }

    final colors = [
      _C.green,
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    final sections = <PieChartSectionData>[];
    int colorIdx = 0;

    final total = countyDistribution.values.fold(
      0.0,
      (sum, val) => sum + (val as num).toDouble(),
    );

    countyDistribution.forEach((key, val) {
      if ((val as num) > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIdx % colors.length],
            value: val.toDouble(),
            title: '',
            radius: 20,
          ),
        );
        colorIdx++;
      }
    });

    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No activities',
          style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: sections,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _C.textMuted,
                    ),
                  ),
                  Text(
                    '${total.toInt()}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _C.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(countyDistribution.length, (index) {
                final key = countyDistribution.keys.elementAt(index);
                final val = countyDistribution[key];
                if ((val as num) == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _C.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _C.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;
  final int? activeIndex;

  _BarChartPainter({required this.dataPoints, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final rawMax = dataPoints.map((d) => d.value).reduce(max);
    int stepSize = (rawMax / 4).ceil();
    if (stepSize > 5) stepSize = ((stepSize / 5).ceil()) * 5;
    if (stepSize == 0) stepSize = 1;
    final maxY = (stepSize * 4).toDouble();

    final gridPaint = Paint()
      ..color = _C.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const leftPadding = 36.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    for (int i = 0; i <= 4; i++) {
      final yValue = stepSize * i;
      final yPos = chartHeight - (yValue / maxY) * chartHeight;

      textPainter.text = TextSpan(
        text: yValue.toString(),
        style: const TextStyle(
          color: _C.textFaint,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - 8));

      double x = leftPadding;
      while (x < size.width) {
        canvas.drawLine(Offset(x, yPos), Offset(x + 5, yPos), gridPaint);
        x += 10;
      }
    }

    final barWidth = min(54.0, (chartWidth / dataPoints.length) * 0.6);
    final spacing =
        (chartWidth - (barWidth * dataPoints.length)) /
        max(1, dataPoints.length - 1);
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB).withOpacity(0.4);

    final labelFontSize = dataPoints.length > 7 ? 10.0 : 12.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final xPos = leftPadding + i * (barWidth + spacing);
      final barHeight = (point.value / maxY) * chartHeight;
      final yPos = chartHeight - barHeight;
      final isActive = activeIndex == i;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xPos, 0, barWidth, chartHeight),
        const Radius.circular(32),
      );
      canvas.drawRRect(bgRect, bgPaint);

      final barPaint = Paint()
        ..shader = isActive
            ? ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFF4ADE80), _C.green],
              )
            : ui.Gradient.linear(
                Offset(xPos, yPos),
                Offset(xPos, chartHeight),
                [const Color(0xFFD1FAE5), const Color(0xFFD1FAE5)],
              );

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xPos, yPos, barWidth, barHeight),
        const Radius.circular(32),
      );
      canvas.drawRRect(barRect, barPaint);

      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(
          color: _C.textMuted,
          fontSize: labelFontSize,
          fontFamily: 'Poppins',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos + (barWidth - textPainter.width) / 2, chartHeight + 12),
      );

      if (isActive) {
        canvas.drawCircle(
          Offset(xPos + barWidth / 2, yPos),
          6,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(xPos + barWidth / 2, yPos),
          4,
          Paint()..color = _C.green,
        );

        textPainter.text = TextSpan(
          children: [
            TextSpan(
              text: '${point.dateLabel}\n',
              style: const TextStyle(
                color: _C.textFaint,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
            const TextSpan(
              text: '● ',
              style: TextStyle(color: _C.green, fontSize: 12),
            ),
            TextSpan(
              text: 'Activities: ${point.value.toInt()}',
              style: const TextStyle(
                color: _C.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        );
        textPainter.layout();

        final tooltipWidth = max(114.0, textPainter.width + 24);
        final rawLeft = xPos - (tooltipWidth / 2) + (barWidth / 2);
        final clampedLeft = rawLeft.clamp(8.0, size.width - tooltipWidth - 8.0);
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(clampedLeft, yPos - 64, tooltipWidth, 52),
          const Radius.circular(16),
        );

        canvas.drawRRect(
          tooltipRect.shift(const Offset(0, 4)),
          Paint()
            ..color = Colors.black.withOpacity(0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);
        textPainter.paint(canvas, Offset(clampedLeft + 12, yPos - 56));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.dataPoints != dataPoints;
}
