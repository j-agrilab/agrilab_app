import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart'; // Import the intl package

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
        } else if (headerName.toLowerCase().contains('date')) {
          // Parse the date, handling potential errors
          DateTime? parsedDate = DateTime.tryParse(value);
          if (parsedDate != null) {
             entry[headerName] = parsedDate;
          }
          else{
             print('parseLocalCSV: Could not parse date value "$value"');
             entry[headerName] = null;
          }
        }
         else {
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
class ChartDataPoint {
  final String? month;
  final int value;
  final DateTime? date; // Add date field

  ChartDataPoint({this.month, required this.value, this.date});

  ChartDataPoint.fromMap(Map<String, dynamic> map)
      : month = map['month'],
        value = map['sales'] != null ? int.parse(map['sales'].toString()) : 0,
        date = map['date'];
}

// --- Chart widget ---
class LocalDataChartScreen extends StatefulWidget {
  final String filePath;
  final List<String> columnNames;

  const LocalDataChartScreen(
      {super.key, required this.filePath, required this.columnNames});

  @override
  _LocalDataChartScreenState createState() => _LocalDataChartScreenState();
}

class _LocalDataChartScreenState extends State<LocalDataChartScreen> {
  List<ChartDataPoint> _chartData = [];
  String _title = 'Loading Data...';
  bool _isLoading = true;
  //Track the max and min visible values
   double _minX = 0;
  double _maxX = 7;
  String _dateColumnName = ''; // To store the name of the date column
  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      final rawData = await parseLocalCSV(widget.filePath);
       // Determine the date column name.
      for (final key in rawData.first.keys) {
        if (key.toLowerCase().contains('date')) {
          _dateColumnName = key;
          break;
        }
      }

      // Convert the raw data to ChartDataPoint
      final List<ChartDataPoint> chartData = rawData.map((item) {
        try {
          return ChartDataPoint(
            month: item['month'], // Keep month if available
            value: item['sales'] != null ? int.parse(item['sales'].toString()) : 0,
            date: item[_dateColumnName], // Use the determined date column
          );
        } catch (e) {
          print("Error converting map $item to ChartDataPoint: $e");
          return ChartDataPoint(month: 'Error', value: 0, date: null);
        }
      }).toList();


      // Filter data for the last two weeks.
      DateTime now = DateTime.now();
      DateTime twoWeeksAgo = now.subtract(const Duration(days: 14));
      List<ChartDataPoint> filteredData = chartData.where((dataPoint) {
        return dataPoint.date != null &&
            (dataPoint.date!.isAfter(twoWeeksAgo) ||
                dataPoint.date!.isAtSameMomentAs(twoWeeksAgo));
      }).toList();

       if (filteredData.isEmpty) {
        setState(() {
          _chartData = [];
          _title = 'No Data for Last Two Weeks';
          _isLoading = false;
        });
        return;
      }
      //set initial visible range
      _minX = 0;
      _maxX = filteredData.length > 7 ? 7: filteredData.length.toDouble();
      setState(() {
        _chartData = filteredData;
        _title = 'Data for Last Two Weeks';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading or processing data: $e');
      setState(() {
        _title = 'Error Loading Data';
        _isLoading = false;
        _chartData = [];
      });
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
        title: Text(_title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  //width: MediaQuery.of(context).size.width * 2,
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
                  child: _chartData.isNotEmpty ? _buildBarChart() : const Center(child: Text('No data available')),
                ),
              ),
      ),
    );
  }

  Widget _buildBarChart() {
  return SfCartesianChart(
    //zoomable and panable
    zoomPanBehavior: ZoomPanBehavior(
      enablePinching: true,
      zoomMode: ZoomMode.x,
      enablePanning: true,
    ),
    primaryXAxis: DateTimeAxis( // Use DateTimeAxis
      title: AxisTitle(text: 'Date'),
      minimum: _minX,
      maximum: _maxX,
       dateFormat: DateFormat('yyyy-MM-dd'),
    ),
    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Value')),
    series: <CartesianSeries>[
      ColumnSeries<ChartDataPoint, DateTime>( // Use DateTime
        dataSource: _chartData,
        xValueMapper: (ChartDataPoint data, _) => data.date, // Use date from data
        yValueMapper: (ChartDataPoint data, _) => data.value,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        color: Colors.blue,
      ),
    ],
    title: ChartTitle(text: 'WSWMD Trends 1m'),
  );
}
}

