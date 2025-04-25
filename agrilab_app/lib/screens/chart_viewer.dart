import 'package:flutter/material.dart';
import 'package:agrilab_app/widgets/chart.dart'; // Import the chart.dart file
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:agrilab_app/utilities/parse_local_csv.dart';

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