import 'package:flutter/material.dart';
import 'package:agrilab_app/widgets/chart.dart'; // Import the chart.dart file
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

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
        // Parse the date.
        dateTime =
            DateTime.parse(row[0]); //  Use DateTime.parse()
        print('parseLocalCSV: Parsed "$row[0]" as $dateTime');
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
          // Parse to double, default to 0 if parsing fails
          entry[columnName] =
              double.tryParse(row[j]?.toString() ?? '0') ?? 0.0;
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

class ChartViewerScreen extends StatefulWidget {
  final String filePath;
  final List<String> columnNames;
  final Map<String, String>? headerNameMappings;

  const ChartViewerScreen({
    super.key,
    required this.filePath,
    required this.columnNames,
    this.headerNameMappings,
  });

  @override
  _ChartViewerScreenState createState() => _ChartViewerScreenState();
}

class _ChartViewerScreenState extends State<ChartViewerScreen> {
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await parseLocalCSV(widget.filePath);
      if (data.isNotEmpty) {
        setState(() {
          _chartData = data;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No data to display.';
          _chartData = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: $e';
        _chartData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Viewer'), // A title for the viewer screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : ChartScreen( // Use the ChartScreen widget
                    rawData: _chartData,
                    columnNames: widget.columnNames,
                    headerNameMappings: widget.headerNameMappings,
                  ),
      ),
    );
  }
}