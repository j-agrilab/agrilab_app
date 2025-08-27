import 'package:flutter/material.dart';
import 'package:agrilab_app/widgets/chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:agrilab_app/utilities/parse_local_csv.dart';
import 'package:agrilab_app/widgets/multiline_chart.dart';
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
          _errorMessage = 'No data to display for the last 24 hours.';
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
        title: const Text('Chart Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _loadData();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        _loadData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChartScreen(
                  rawData: _chartData,
                  columnNames: widget.columnNames,
                  headerNameMappings: widget.headerNameMappings,
                ),
              ),
    );
  }
}
