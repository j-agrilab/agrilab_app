import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:agrilab_app/models/chart_data_point.dart';

// --- Chart widget ---
class ChartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawData;
  final List<String> columnNames;
  final Map<String, String>? headerNameMappings;

  const ChartScreen({
    super.key,
    required this.rawData,
    required this.columnNames,
    this.headerNameMappings,
  });

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<LineSeries<ChartDataPoint, DateTime>> _seriesData = [];
  String _title = 'Chart';
  DateTime? _minX, _maxX;
  // Add these variables for zoom and pan.  Syncfusion uses a different approach.
  //double _viewportMinX = 0;
  //double _viewportMaxX = 0;
  //final _chartKey = GlobalKey<State<LineChart>>();  // Not needed for Syncfusion
  //Track the chart zoom and pan
  late ZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;
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
        });
        return;
      }

      final List<String> availableColumnNames = rawData.isNotEmpty
          ? rawData.first.keys.where((key) => key != 'datetime').toList()
          : [];

      // Use provided column names, or all available if none provided.
      final List<String> columnNames = widget.columnNames.isNotEmpty
          ? widget.columnNames
          : availableColumnNames; // Use all available if none provided
      print('_loadChartData: Using columns: $columnNames');

      _minX = rawData.isNotEmpty ? rawData.first['datetime'] : null;
      _maxX = rawData.isNotEmpty ? rawData.last['datetime'] : null;
      print('_loadChartData: minX: $_minX, maxX: $_maxX');

      // Initialize viewport.  Handled differently in Syncfusion.
      /*if (_minX != null && _maxX != null) {
        _viewportMinX = _minX!.millisecondsSinceEpoch.toDouble();
        _viewportMaxX = _maxX!.millisecondsSinceEpoch.toDouble();
      }*/

      List<LineSeries<ChartDataPoint, DateTime>> lineSeriesList = [];

      for (var columnName in columnNames) {
        final String label =
            widget.headerNameMappings?[columnName] ?? columnName;
        print('_loadChartData: Processing column: $columnName, label: $label');

        List<ChartDataPoint> chartData = rawData.map((item) {
          final dataPoint = ChartDataPoint.fromMap(
            map: item,
            columnName: columnName,
            //label: label,  // Label not directly used in Syncfusion LineSeries
          );
          return dataPoint;
        }).toList();
        print(
            '_loadChartData: Created ${chartData.length} data points for column $columnName');

        if (chartData.isNotEmpty) {
          lineSeriesList.add(
            LineSeries<ChartDataPoint, DateTime>(
              name: label, // Use the label (or column name) as the series name
              dataSource: chartData,
              xValueMapper: (ChartDataPoint data, _) => data.x,
              yValueMapper: (ChartDataPoint data, _) => data.y,
              color: _getColorForColumn(columnName),
              markerSettings:
                  const MarkerSettings(isVisible: false), // Hide markers for cleaner look
            ),
          );
        } else {
          print(
              '_loadChartData: No data points for column $columnName.  Skipping.');
        }
      }

      setState(() {
        _title = 'Local Data Chart';
        _seriesData = lineSeriesList;
        _isLoading =
            false; //  Set loading to false here, after the data is processed.
      });
    } catch (e) {
      print('_loadChartData: Error loading or processing data: $e');
      setState(() {
        _title = 'Error Loading Data';
        _seriesData = [];
        _isLoading = false; // Ensure loading is set to false on error
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
    return  _isLoading ? const Center(child: CircularProgressIndicator()) :
      SizedBox(
      width: 800, // Increased width.
      height: 400,
      child: Padding(
        padding: const EdgeInsets.all(10),
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
          child:
           SfCartesianChart(
            title: ChartTitle(text: _title),
            legend: const Legend(
              isVisible: true,
              position: LegendPosition
                  .bottom, // Place legend at the bottom for better layout
            ),
            primaryXAxis: DateTimeAxis(
              dateFormat:
                  DateFormat('yyyy-MM-dd HH:mm:ss'), // Consistent date formatting
              title: AxisTitle(text: 'Time'),
              //labelRotation: 45, //  No overlapping labels.
            ),
            primaryYAxis:
                NumericAxis(title: AxisTitle(text: 'Value')), // Add y-axis title
            series: _seriesData,
            zoomPanBehavior: _zoomPanBehavior,
            // Add the tooltip behavior
            tooltipBehavior: TooltipBehavior(
              enable: true,
              shared:
                  true, // Display tooltip for all series at the touched point
            ),
          ),
        ),
      ),
    );
  }
}


