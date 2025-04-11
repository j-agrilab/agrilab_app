import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:io';

// --- Utility function to parse local CSV data ---
Future<List<Map<String, dynamic>>> parseLocalCSV(String filePath) async {
  try {
    print('parseLocalCSV: Loading CSV file from $filePath');
    final rawData = await File(filePath).readAsString();
    final List<List<dynamic>> records =
        const CsvToListConverter().convert(rawData, eol: "\n"); //split by new line

    if (records.isEmpty) {
      print('parseLocalCSV: CSV file is empty');
      return [];
    }

    final header = records.first.map((h) => h.toString().toLowerCase()).toList();
    final data = <Map<String, dynamic>>[];

    for (int i = 1; i < records.length; i++) {
      final row = records[i];
      // Check for row length mismatch
      if (row.length < header.length) {
        print(
            'parseLocalCSV: Skipping row $i, row length (${row.length}) is less than header length (${header.length})');
        continue;
      }
      //check for empty row
      if (row.every((cell) => cell == null || cell.toString().trim() == '')) {
        print('parseLocalCSV: Skipping empty row $i');
        continue;
      }

      final entry = <String, dynamic>{};
      for (int j = 0; j < header.length && j < row.length; j++) {
        //trim added to remove extra spaces
        final headerName = header[j];
        final value = row[j].toString().trim();
        if (headerName == 'month') {
          entry[headerName] = value;
        } else {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            entry[headerName] = intValue;
          } else {
            print(
                'parseLocalCSV: Warning: Could not parse value "$value" as int for column "$headerName" in row $i.  Setting to 0.');
            entry[headerName] =
                0; // Or consider skipping the row, or using null
          }
        }
      }
      data.add(entry);
    }
    print('parseLocalCSV: Parsed ${data.length} data points');
    return data;
  } catch (e) {
    print('Error parsing CSV file $filePath: $e');
    return [];
  }
}

// --- Data class to hold chart data ---
class ChartDataPoint { // Renamed from SalesData
  final String month;
  final int value; // Renamed from sales

  ChartDataPoint(this.month, this.value);

  // Named constructor to create ChartDataPoint from a map
  ChartDataPoint.fromMap(Map<String, dynamic> map)
      : month = map['month'] ??
            '', // Provide default values in case of null
        value = map['sales'] != null // still using sales from the map
            ? int.parse(map['sales'].toString())
            : 0;
}

// --- Chart widget ---
class LocalDataChartScreen extends StatefulWidget {
  final String filePath;
  final List<String> columnNames;

  const LocalDataChartScreen({
    super.key,
    required this.filePath,
    required this.columnNames, // Initialize columnNames here
  });

  @override
  _LocalDataChartScreenState createState() => _LocalDataChartScreenState();
}

class _LocalDataChartScreenState extends State<LocalDataChartScreen> {
  List<charts.Series<ChartDataPoint, String>> _seriesData = []; // Changed type
  String _title = 'Loading Data...'; // Initial title
  bool _isLoading = true;
  //final List<String> columnNames; // Remove this line

  @override
  void initState() {
    super.initState();
    _loadChartData(); // Load data when the widget is initialized
  }

  // --- Function to load and process data ---
  Future<void> _loadChartData() async {
    try {
      // 1. Load data from the local CSV file.
      final rawData = await parseLocalCSV(widget.filePath);

      // 2. Convert the raw data (List<Map<String, dynamic>>) into a List<ChartDataPoint>
      final List<ChartDataPoint> chartData = rawData.map((item) { // Changed type
        //  Error handling during the conversion.
        try {
          return ChartDataPoint.fromMap(item);
        } catch (e) {
          print("Error converting map $item to ChartDataPoint: $e");
          return ChartDataPoint('Error', 0); // Return a default value on error.
        }
      }).toList();

      // 3. Create the chart series.
      _seriesData = [
        charts.Series<ChartDataPoint, String>( // Changed type
          id: 'Data', // Changed id
          data: chartData,
          domainFn: (ChartDataPoint dataPoint, _) => dataPoint.month, // Changed
          measureFn: (ChartDataPoint dataPoint, _) => dataPoint.value, // Changed
          colorFn: (_, index) {
            if (index! < 3) {
              return charts.MaterialPalette.blue.shadeDefault;
            }
            return charts.MaterialPalette.red.shadeDefault;
          },
          labelAccessorFn: (ChartDataPoint dataPoint, _) => '${dataPoint.value}', // Changed
        ),
      ];

      // 4. Update the UI.
      setState(() {
        _title = 'Yearly Data'; // Updated title
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors during data loading.
      print('Error loading or processing data: $e');
      setState(() {
        _title = 'Error Loading Data'; // Set an error title
        _isLoading = false;
        _seriesData = []; //set to empty
      });
      // Show error message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chart data: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title), // Use the dynamic title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  //width: MediaQuery.of(context).size.width * 2, // Make it wider than the screen
                  height: 400,
                  padding: const EdgeInsets.all(10),
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
                      ? charts.BarChart(
                          //check if _seriesData is empty
                          _seriesData,
                          animate: true,
                          behaviors: [
                            charts.ChartTitle(
                              'Yearly Data', // Updated title
                              behaviorPosition: charts.BehaviorPosition.top,
                              titleStyle: const charts.TextStyleSpec(
                                fontSize: 14,
                                color: charts.MaterialPalette.black,
                              ),
                            ),
                            charts.PanAndZoom(
                              allowHorizontal: true,
                              allowVertical: true,
                            ),
                            charts.Legend(
                              position: charts.BehaviorPosition.bottom,
                              showMeasures: true,
                              legendDefaultMeasure:
                                  charts.LegendDefaultMeasure.sum,
                              measureFormatter: (num? value) {
                                return value == null ? '-' : '${value}';
                              },
                            ),
                            charts.DataTable(
                              showRowSeparator: true,
                              tableCellPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              defaultTextStyle: const TextStyle(fontSize: 10),
                            ),
                          ],
                          domainAxis: const charts.OrdinalAxisSpec(
                            renderSpec: charts.SmallTickRendererSpec(
                              labelRotation: 315,
                              labelStyle: const charts.TextStyleSpec(
                                fontSize: 12,
                                color: charts.MaterialPalette.black,
                              ),
                            ),
                          ),
                          primaryMeasureAxis: const charts.NumericAxisSpec(
                            tickProviderSpec:
                                charts.StaticNumericTickProviderSpec(
                              [
                                charts.TickSpec(0),
                                charts.TickSpec(25),
                                charts.TickSpec(50),
                                charts.TickSpec(75),
                                charts.TickSpec(100),
                                charts.TickSpec(125),
                              ],
                            ),
                            renderSpec: const charts.SmallTickRendererSpec(
                              labelStyle: const charts.TextStyleSpec(
                                fontSize: 12,
                                color: charts.MaterialPalette.black,
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text('No data available')), //show no data available
                ),
              ),
      ),
    );
  }
}

