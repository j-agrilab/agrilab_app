import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:agrilab_app/models/chart_data_point.dart';


/*
// --- Chart widget ---
class ChartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawData;
  final Map<String, String>? headerNameMappings;

  const ChartScreen({
    super.key,
    required this.rawData,
    Names,
    this.headerNameMappings,
  });

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<LineSeries<ChartDataPoint, DateTime>> _seriesData = [];
  String _title = 'Chart';
  DateTime? _minX, _maxX;
  late ZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;
  // Store Y-Axis
  final Map<String, String> _yAxisTitle = {};
  final List<NumericAxis> _secondaryYAxis = [];
  // Use a map to track visibility, defaulting to true.
  final Map<String, bool> _legendVisibility = {};
  final List<String> _legendKeys =
      []; // To store the order of legend items.  Important!
  // Key for the chart to force a rebuild.
  final GlobalKey<State<SfCartesianChart>> _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      zoomMode: ZoomMode.xy,
      enablePanning: true,
    );
  }

  Future<void> _loadChartData() async {
    try {
      print('_loadChartData: Start loading chart data');

      final List<Map<String, dynamic>> rawData = widget.rawData;
      if (rawData.isEmpty) {
        print('_loadChartData: No data available');
        setState(() {
          _title = 'No Data Available';
          _seriesData = [];
          _isLoading = false;
        });
        return;
      }

      final List<String> availableColumnNames = rawData.isNotEmpty
          ? rawData.first.keys.where((key) => key != 'datetime').toList()
          : [];

      // Use provided column names, or all available if none provided.
      final List<String> columnNames = widget.columnNames.isNotEmpty
          ? widget.columnNames
          : availableColumnNames;
      print('_loadChartData: Using columns: $columnNames');

      _minX = rawData.isNotEmpty ? rawData.first['datetime'] : null;
      _maxX = rawData.isNotEmpty ? rawData.last['datetime'] : null;
      print('_loadChartData: minX: $_minX, maxX: $_maxX');

      List<LineSeries<ChartDataPoint, DateTime>> lineSeriesList = [];
      List<NumericAxis> secondaryYAxisList = [];
      _yAxisTitle.clear();
      _legendVisibility.clear(); // Clear existing visibility states.
      _legendKeys.clear(); // Clear the legend keys

      for (var columnName in columnNames) {
        final String label =
            widget.headerNameMappings?[columnName] ?? columnName;
        print('_loadChartData: Processing column: $columnName, label: $label');

        List<ChartDataPoint> chartData = rawData.map((item) {
          final dataPoint = ChartDataPoint.fromMap(
            map: item,
            columnName: columnName,
          );
          return dataPoint;
        }).toList();
        print(
            '_loadChartData: Created ${chartData.length} data points for column $columnName');

        if (chartData.isNotEmpty) {
          // Determine min and max for the Y-Axis
          double minY = chartData.first.y;
          double maxY = chartData.first.y;
          for (final dataPoint in chartData) {
            if (dataPoint.y < minY) {
              minY = dataPoint.y;
            }
            if (dataPoint.y > maxY) {
              maxY = dataPoint.y;
            }
          }

          // Create a unique name for the secondary axis.
          String yAxisName = 'yAxis_$columnName';

          // Store the y-axis title
          _yAxisTitle[columnName] = label;
          _legendVisibility[label] =
              true; // Initialize all series as visible.
          _legendKeys.add(
              label); // Store the label.  This is important for the onLegendTapped handler
          final yAxis = NumericAxis(
            name: yAxisName,
            title: AxisTitle(text: label),
            minimum: minY,
            maximum: maxY,
          );

          secondaryYAxisList.add(yAxis);

          lineSeriesList.add(
            LineSeries<ChartDataPoint, DateTime>(
              name: label,
              dataSource: chartData,
              xValueMapper: (ChartDataPoint data, _) => data.x,
              yValueMapper: (ChartDataPoint data, _) => data.y,
              color: _getColorForColumn(columnName),
              markerSettings: const MarkerSettings(isVisible: false),
              yAxisName: yAxisName,
            ),
          );
        } else {
          print(
              '_loadChartData: No data points for column $columnName.  Skipping.');
        }
      }

      // *IMPORTANT*:  Move the setState *inside* the data loading
      setState(() {
        _title = 'Local Data Chart';
        _seriesData = lineSeriesList;
        _secondaryYAxis.clear();
        _secondaryYAxis.addAll(secondaryYAxisList);
        _isLoading = false;
      });
      // No need to call it here.
    } catch (e) {
      print('_loadChartData: Error loading or processing data: $e');
      setState(() {
        _title = 'Error Loading Data';
        _seriesData = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chart data: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  // Function to select color based on the column name.
  Color _getColorForColumn(String columnName) {
    switch (columnName.toLowerCase()) {
      case 'tai':
        return Colors.blue;
      case 'tai_1':
        return Colors.green;
      case 'tai_2':
        return Colors.red;
      case 'tai_3':
        return Colors.yellow;
      case 'tai_4':
        return Colors.purple;
      case 'dcfm smoothbyfilter':
        return Colors.orange;
      case 'o2':
        return Colors.pink;
      case 'tao':
        return Colors.teal;
      case 'tao_r1':
        return Colors.amber;
      case 'tao_r2':
        return Colors.brown;
      case 'tao_r3':
        return Colors.cyan;
      case 'tao_r4':
        return Colors.deepOrange;
      case 'twi':
        return Colors.deepPurple;
      case 'two':
        return Colors.indigo;
      default:
        return Colors.blue; // Default color.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: 400,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(3, 3),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: SfCartesianChart(
                      key: _chartKey, // Assign the key
                      title: ChartTitle(text: _title),
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      onLegendTapped: (LegendTapArgs args) {
                        // Null check for args.seriesIndex
                        if (args.seriesIndex != null) {
                          String tappedLegendItem =
                              _legendKeys[args.seriesIndex!];
                          print('Tapped legend: $tappedLegendItem');
                          setState(() {
                            _legendVisibility[tappedLegendItem] =
                                !_legendVisibility[tappedLegendItem]!;
                          });
                          // No need to call _updateChart() here.  The setState will trigger a rebuild
                        } else {
                          print('args.seriesIndex is null');
                          // Handle the null case
                        }
                      },
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('yyyy-MM-dd HH:mm:ss'),
                        title: AxisTitle(text: 'Time'),
                      ),
                      primaryYAxis: _getYAxis(), // Use the single Y-axis getter
                      axes: [], //  No secondary axes.
                      series: _getSeriesData(),
                      zoomPanBehavior: _zoomPanBehavior,
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        shared: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  //  Helper Functions
  List<LineSeries<ChartDataPoint, DateTime>> _getSeriesData() {
    return _seriesData.map((series) {
      // Use the visibility state.
      final isVisible = _legendVisibility[series.name] ?? true;
      return LineSeries<ChartDataPoint, DateTime>(
        name: series.name,
        dataSource: series.dataSource,
        xValueMapper: series.xValueMapper,
        yValueMapper: series.yValueMapper,
        color: _getColorForColumn(series.name!),
        opacity: isVisible ? 1 : 0.5,
        markerSettings: const MarkerSettings(isVisible: false),
        yAxisName:
            'primaryYAxis', // All series use the primary Y axis.
      );
    }).toList();
  }

  NumericAxis _getYAxis() {
    // Check if all series are visible
    bool allVisible = true;
    for (bool visibility in _legendVisibility.values) {
      if (!visibility) {
        allVisible = false;
        break;
      }
    }

    if (allVisible) {
      // If all are visible, return an axis with no labels
      return NumericAxis(
        labelStyle: const TextStyle(fontSize: 0),
        majorTickLines: const MajorTickLines(size: 0),
        minorTickLines: const MinorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      );
    } else {
      // Otherwise, return a standard Y axis, with dynamic range.
      double overallMaxY = double.negativeInfinity;
      // Find the maximum Y value across all *visible* series.
      for (final series in _seriesData) {
        if (_legendVisibility[series.name] ??
            true) { // Only consider visible series
          for (final dataPoint in series.dataSource!) {
            if (dataPoint.y > overallMaxY) {
              overallMaxY = dataPoint.y;
            }
          }
          
        }
      }
      // Round up the maximum Y value to the nearest 10.
      overallMaxY = (overallMaxY / 10).ceil() * 10;

      return NumericAxis(
        title: AxisTitle(text: 'Value'),
        minimum: 0, // Fixed minimum
        maximum: overallMaxY, // Dynamic maximum
      );
    }
  }

}

*/