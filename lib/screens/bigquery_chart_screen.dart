// lib/screens/bigquery_chart_screen.dart
import 'package:flutter/material.dart';
import '../widgets/chart_widget.dart';
import '../models/chart_data.dart';
import '../services/mock_bigquery_service.dart'; // Import the mock service
import '../constants/api_constants.dart'; // You might not need this anymore

class BigQueryChartScreen extends StatefulWidget {
  final List<String> columnNames;
  final String? filePath; // Add an optional file path

  const BigQueryChartScreen({
    super.key,
    required this.columnNames,
    this.filePath, // Make filePath optional
  });

  @override
  _BigQueryChartScreenState createState() => _BigQueryChartScreenState();
}

class _BigQueryChartScreenState extends State<BigQueryChartScreen> {
  List<ChartData> _chartData = [];
  bool _isLoading = true;
  //final BigQueryService _bigQueryService = BigQueryService(); // Use the real service
  final MockBigQueryService _bigQueryService =
      MockBigQueryService(); // Use the mock service for local files

  List<Color> lineColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    print(_chartData);
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _chartData = await _bigQueryService.fetchData(
        tableId: WATER_TRENDS_ID, // This might not be relevant for local files
        queryString:
            'ORDER BY PARSE_TIMESTAMP(\'%Y-%m-%d %H:%M:%S\', Date)', // This might need adaptation
        filePath: widget.filePath, // Pass the file path to the mock service
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chart from BigQuery Service')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chartData.isEmpty
              ? const Center(child: Text('No data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ChartWidget(
                    chartData: _chartData,
                    columnNames: widget.columnNames,
                    lineColors: lineColors,
                  ),
                ),
    );
  }
}