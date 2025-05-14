import 'package:flutter/material.dart';
import 'package:material_charts/material_charts.dart';


class MultilineChart extends StatefulWidget {
  final List<Map<String, dynamic>> rawData;
  final String? title;
  final Map<String, String>? headerNameMappings;

  const MultilineChart({
    super.key,
    required this.rawData,
    this.title,
    this.headerNameMappings,
  });

   @override
  _MultilineChartState createState() => _MultilineChartState();

}

class _MultilineChartState extends State<MultilineChart> {
  List<ChartSeries> _seriesData = [];
  DateTime? _minX, _maxX;
  bool _isLoading = true;
  String _title = "Multiline Chart";

   @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      print('_loadChartData: Start loading chart data');

      final List<Map<String, dynamic>> rawData = widget.rawData;
      final List<String> availableColumnNames = rawData.isNotEmpty
          ? rawData.first.keys.where((key) => key != 'datetime').toList()
          : [];
      
      _minX = rawData.isNotEmpty ? rawData.first['datetime'] : null;
      _maxX = rawData.isNotEmpty ? rawData.last['datetime'] : null;

      List<ChartSeries> chartSeriesList = [];
      LegendPosition legendPosition = LegendPosition.right;

      
    
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
                  ),
                  child: MultiLineChart  (
                    series: ,)
            }
          );
  }

}