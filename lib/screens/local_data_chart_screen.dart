import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- Utility function to parse local CSV data ---
Future<List<Map<String, dynamic>>> parseLocalCSV(String filePath) async {
  try {
    print('parseLocalCSV: Loading CSV file from $filePath');
    // Use rootBundle to load from assets
    final rawData = await rootBundle.loadString(filePath);
    final List<List<dynamic>> records =
        const CsvToListConverter().convert(rawData);

    if (records.isEmpty) {
      print('parseLocalCSV: CSV file is empty');
      return [];
    }

    final header = records.first.map((h) => h.toString().toLowerCase()).toList();
    //  datetime
    final dateColumnName = header.first;
    final valueColumnNames = header.sublist(1); // Get all but the first column
    print('parseLocalCSV: Header: $header');

    final List<Map<String, dynamic>> data = [];

    for (int i = 1; i < records.length; i++) {
      final row = records[i];
      if (row.length <= 1) {
        print(
            'parseLocalCSV: Skipping row $i because it has less than 2 columns');
        continue; // Skip rows with no data
      }

      DateTime? dateTime;
      try {
        // Parse the date using the month-first format "MM-dd-yyyy"
        dateTime = DateFormat("HH:mm:ss MM-dd-yyyy").parse(row[0]);
        print(
            'parseLocalCSV: Parsed "$row[0]" as $dateTime using HH:mm:ss MM-dd-yyyy');
      } catch (e) {
        print('parseLocalCSV: Error parsing date: ${row[0]}, error: $e');
        dateTime = null; // Set to null if parsing fails
      }

      if (dateTime != null) {
        // Only include data if the date is valid
        final entry = <String, dynamic>{};
        entry['datetime'] = dateTime; // Store parsed DateTime
        for (int j = 1;
            j < row.length && j < valueColumnNames.length + 1;
            j++) {
          final columnName = valueColumnNames[j - 1];
          entry[columnName] = row[j];
        }
        data.add(entry);
      }
    }
    print('parseLocalCSV: Parsed ${data.length} data points');
    // Print the first 5 rows of data
    if (data.isNotEmpty) {
      print('parseLocalCSV: First 5 rows of data:');
      for (int i = 0; i < (data.length > 5 ? 5 : data.length); i++) {
        print(data[i]);
      }
    }
    return data;
  } catch (e) {
    print('parseLocalCSV: Error parsing CSV file $filePath: $e');
    return [];
  }
}

// --- Data class to hold chart data ---
class ChartDataPoint {
  final DateTime x;
  final double y;
  final String label;

  ChartDataPoint({required this.x, required this.y, required this.label});

  // Named constructor to create ChartDataPoint from a map
  ChartDataPoint.fromMap({
    required Map<String, dynamic> map,
    required String columnName,
    required String label,
  })  : x = map['datetime'], // Use the parsed DateTime
        y = (double.tryParse(map[columnName]?.toString() ?? '0') ?? 0.0),
        label = label;
}

// --- Chart widget ---
class LocalDataChartScreen extends StatefulWidget {
  final String filePath;
  final List<String> columnNames;
  final Map<String, String>? headerNameMappings;

  const LocalDataChartScreen({
    super.key,
    required this.filePath,
    required this.columnNames, // Ensure this is passed correctly
    this.headerNameMappings,
  });

  @override
  _LocalDataChartScreenState createState() => _LocalDataChartScreenState();
}

class _LocalDataChartScreenState extends State<LocalDataChartScreen> {
  List<LineChartBarData> _seriesData = [];
  String _title = 'Loading Data...';
  bool _isLoading = true;
  DateTime? _minX, _maxX;
  // Add these variables for zoom and pan
  double _viewportMinX = 0;
  double _viewportMaxX = 0;
  final _chartKey = GlobalKey<State<LineChart>>();
  // Add a TransformationController
  final TransformationController _transformationController =
      TransformationController();
  // Add a ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void dispose() {
    // Dispose the TransformationController
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    try {
      print('_loadChartData: Loading chart data from ${widget.filePath}');
      final rawData = await parseLocalCSV(widget.filePath);
      if (rawData.isEmpty) {
        print('_loadChartData: No data available after parsing CSV');
        setState(() {
          _title = 'No Data Available';
          _isLoading = false;
          _seriesData = [];
        });
        return;
      }

      final List<String> availableColumnNames = rawData.isNotEmpty
          ? rawData.first.keys.where((key) => key != 'datetime').toList()
          : [];

      // Use provided column names or all available
      final List<String> columnNames = widget.columnNames;

      print('_loadChartData: Using columns: $columnNames');

      _minX = rawData.isNotEmpty ? rawData.first['datetime'] : null;
      _maxX = rawData.isNotEmpty ? rawData.last['datetime'] : null;
      print('_loadChartData: minX: $_minX, maxX: $_maxX');

      // Initialize viewport
      if (_minX != null && _maxX != null) {
        _viewportMinX = _minX!.millisecondsSinceEpoch.toDouble();
        _viewportMaxX = _maxX!.millisecondsSinceEpoch.toDouble();
      }

      List<LineChartBarData> lineBarsData = []; // Use a local variable.

      for (var columnName in columnNames) {
        final String label =
            widget.headerNameMappings?[columnName] ?? columnName;
        print('_loadChartData: Processing column: $columnName, label: $label');

        List<ChartDataPoint> chartData = rawData.map((item) {
          final dataPoint = ChartDataPoint.fromMap(
            map: item,
            columnName: columnName,
            label: label,
          );
          return dataPoint;
        }).toList();
        print(
            '_loadChartData: Created ${chartData.length} data points for column $columnName');

        if (chartData.isNotEmpty) {
          lineBarsData.add(
            // Add data for each line.
            LineChartBarData(
              spots: chartData.map((dataPoint) {
                return FlSpot(
                  dataPoint.x.millisecondsSinceEpoch.toDouble(),
                  dataPoint.y,
                );
              }).toList(),
              isCurved: true,
              belowBarData: BarAreaData(show: false),
              color: _getColorForColumn(columnName),
            ),
          );
        } else {
          print(
              '_loadChartData: No data points for column $columnName.  Skipping.');
        }
      }
      print(
          '_loadChartData: Created ${lineBarsData.length} LineChartBarData objects');

      setState(() {
        _title = 'Local Data Chart';
        _isLoading = false;
        _seriesData =
            lineBarsData; // Assign the built list to the class variable.
      });
    } catch (e) {
      print('_loadChartData: Error loading or processing data: $e');
      setState(() {
        _title = 'Error Loading Data';
        _isLoading = false;
        _seriesData = [];
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox( // Use SizedBox to constrain the chart's size.
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
                    child: _seriesData.isNotEmpty
                        ? LineChart(
                            key: _chartKey,
                            LineChartData(
                              lineBarsData: _seriesData,
                              minX: _viewportMinX,
                              maxX: _viewportMaxX,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      final dateTime =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              value.toInt());
                                      final formattedDate =
                                          DateFormat('HH:mm:ss').format(dateTime);
                                      return Text(formattedDate);
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchCallback: (FlTouchEvent event,
                                    LineTouchResponse? response) {
                                  if (response == null ||
                                      response.lineBarSpots == null) {
                                    return;
                                  }
                                  for (var spot in response.lineBarSpots!) {
                                    print(
                                        'Touched spot on line ${spot.barIndex}, x: ${spot.x}, y: ${spot.y}');
                                  }
                                },
                              ),
                              // Add interactive features
                              clipData: const FlClipData.horizontal(), // Add this line
                            ),
                          )
                        : const Center(child: Text('No data available')),
                  ),
                ),
              ),
      ),
    );
  }
}

