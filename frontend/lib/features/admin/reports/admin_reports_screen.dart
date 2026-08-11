import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/admin_reports_provider.dart';
import 'utils/pdf_export_utils.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _reportGenerated = false;

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
                final periods = ['This Week', 'This Month', 'This Quarter', 'This Year', 'All Time'];
                final departments = List<String>.from(filterData['departments'] ?? ['All Departments']);
                final supervisors = List<Map<String, dynamic>>.from(filterData['supervisors'] ?? [{'id': 'All Supervisors', 'name': 'All Supervisors'}]);
                final counties = List<String>.from(filterData['counties'] ?? ['All Counties']);

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
                            (val) => ref.read(adminReportFiltersProvider.notifier).state = filters.copyWith(period: val),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'Department',
                            filters.department,
                            departments,
                            (val) => ref.read(adminReportFiltersProvider.notifier).state = filters.copyWith(department: val),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'Supervisor',
                            filters.supervisorId,
                            supervisors.map((s) => s['id'] as String).toList(),
                            (val) => ref.read(adminReportFiltersProvider.notifier).state = filters.copyWith(supervisorId: val),
                            displayItems: supervisors.map((s) => s['name'] as String).toList(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdown(
                            'County',
                            filters.county,
                            counties,
                            (val) => ref.read(adminReportFiltersProvider.notifier).state = filters.copyWith(county: val),
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
                            ref.read(adminReportFiltersProvider.notifier).state = AdminReportFilters();
                            setState(() {
                              _reportGenerated = false;
                            });
                          },
                          icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 18),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              await PdfExportUtils.generateAndDownloadReport(data);
                            },
                            icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                            label: const Text('Export PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1BA654),
                              side: const BorderSide(color: Color(0xFF1BA654)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                child: _buildActivityLineChart(data['trendData'] as List<dynamic>? ?? []),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildChartCard(
                                title: 'County Distribution',
                                child: _buildCountyPieChart(data['countyDistribution'] as Map<String, dynamic>? ?? {}),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Expanded(child: Center(child: Text('Error: $err'))),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {List<String>? displayItems}) {
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
              icon: Icon(PhosphorIcons.caretDown(), color: const Color(0xFF9CA3AF), size: 16),
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

  Widget _buildActivityLineChart(List<dynamic> trendData) {
    if (trendData.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      spots.add(FlSpot(i.toDouble(), (trendData[i]['value'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null, // Let it auto-calc
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE5E7EB),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < trendData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      trendData[value.toInt()]['label']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontFamily: 'Inter'),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontFamily: 'Inter'),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountyPieChart(Map<String, dynamic> countyDistribution) {
    if (countyDistribution.isEmpty) {
      return const Center(child: Text('No distribution data'));
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    final sections = <PieChartSectionData>[];
    int colorIdx = 0;

    countyDistribution.forEach((key, val) {
      if ((val as num) > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIdx % colors.length],
            value: val.toDouble(),
            title: key,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
        colorIdx++;
      }
    });

    if (sections.isEmpty) {
      return const Center(child: Text('No activities in selected period'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }
}
