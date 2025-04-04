import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data.dart';

class ChartWidget extends StatelessWidget {
  final List<ChartData> chartData;
  final List<String> columnNames;
  final List<Color> lineColors;

  const ChartWidget({super.key, 
    required this.chartData,
    required this.columnNames,
    required this.lineColors,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: _buildLineBarsData(),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    if (chartData.isEmpty) return [];

    List<LineChartBarData> lineBars = [];
    for (int i = 0; i < columnNames.length; i++) {
      List<FlSpot> spots = chartData
          .map((data) => FlSpot(chartData.indexOf(data).toDouble(),
              data.data[columnNames[i]]?.toDouble() ?? 0))
          .toList();

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColors[i % lineColors.length], // Cycle through colors
        ),
      );
    }
    return lineBars;
  }
}