// --- Data class to hold chart data ---
class ChartDataPoint {
  final DateTime x;
  final double y;
  // Add a series name.  This is important for multi-line charts.
  final String seriesName;

  ChartDataPoint({required this.x, required this.y, required this.seriesName});

  // Named constructor to create ChartDataPoint from a map
  ChartDataPoint.fromMap({
    required Map<String, dynamic> map,
    required String columnName,
  })  : x = map['datetime'],
        y = (double.tryParse(map[columnName]?.toString() ?? '0') ?? 0.0),
        seriesName = columnName; // Use the columnName as the series name
}
