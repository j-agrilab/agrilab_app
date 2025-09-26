import 'package:flutter/material.dart';
import 'dart:math';
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
  List<Map<String, dynamic>> _allData = []; 
  DateTime? _minX, _maxX;
  double? _minY, _maxY;
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
      
      // 1. Sort the data by datetime to ensure correct order.
      _allData = List.from(rawData); //copy
      _allData.sort((a, b) =>
          (a['datetime'] as DateTime).compareTo(b['datetime'] as DateTime));
      print("alldata : $_allData");
      // 2. Find the latest date from the sorted data.

      final DateTime mostRecent = _allData.last['datetime'];
      final DateTime dayAgo = mostRecent.subtract(Duration(days: 1));
      _minX = dayAgo;
      _maxX = mostRecent;
      _minY = 0;
      _maxY = 150;

      List<ChartSeries> chartSeriesList = [];
      LegendPosition legendPosition = LegendPosition.right;
      
      // Create list of data points
      for (final column in availableColumnNames) {
        //print("loading column $column");
        final String label = widget.headerNameMappings?[column] ?? column;
        List<ChartDataPoint> dataPoints = []; 
        for (final row in rawData) {
          final dataPoint = ChartDataPoint(value: row[column], label: row['datetime'].toString());
          dataPoints.add(dataPoint);
        }
        // Turn into ChartSeries and add to data set
        final ChartSeries chartSeries = ChartSeries(
          name: column,
          dataPoints: dataPoints,
          color: Color.fromRGBO(Random().nextInt(255), Random().nextInt(255), Random().nextInt(255), 1)
        );
        print("added chart series");
        chartSeriesList.add(chartSeries);

      }

      setState(() {
        _seriesData = chartSeriesList;
        _isLoading = false;
      });

    
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
    final style = MultiLineChartStyle(
      backgroundColor: const Color.fromARGB(255, 29, 21, 21),
      colors: [Colors.blue, Colors.green, Colors.red],
      smoothLines: true,
      showPoints: false,
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
      tooltipStyle: const MultiLineTooltipStyle(
        threshold: 20,
      ),
      forceYAxisFromZero: false,
      crosshair: CrosshairConfig(
        enabled: true,
        lineColor: Colors.grey.withOpacity(0.5),
      ),
      legendPosition: LegendPosition.bottom,
      
    );

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
                    child: MultiLineChart(
                      series: _seriesData,
                      style: style,
                      height: 700,
                      width: 800,
                      enableZoom: true,
                      enablePan: true,
                      
                    ),
                    ),
                  ),
                );
            }
          );
          
  }

}