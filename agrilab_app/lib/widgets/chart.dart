import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:agrilab_app/models/chart_data_point.dart';


/*
// --- Chart widget ---
class ChartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawData;
  final Map<String, String>? headerNameMappings;

  const ChartScreen({
    super.key,
    required this.rawData,
    Names,
    this.headerNameMappings,
  });

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<LineSeries<ChartDataPoint, DateTime>> _seriesData = [];
  String _title = 'Chart';
  DateTime? _minX, _maxX;
  late ZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;
  // Store Y-Axis
  final Map<String, String> _yAxisTitle = {};
  final List<NumericAxis> _secondaryYAxis = [];
  // Use a map to track visibility, defaulting to true.
  final Map<String, bool> _legendVisibility = {};
  final List<String> _legendKeys =
      []; // To store the order of legend items.  Important!
  // Key for the chart to force a rebuild.
  final GlobalKey<State<SfCartesianChart>> _chartKey = GlobalKey();


  // Series filtering state
  Map<String, bool> _seriesVisibility = {};
  List<String> _availableColumns = [];

  // Time navigation state
  double _timePosition = 0.0;
  Duration _currentTimeWindow = const Duration(hours: 24);
  DateTime? _viewStartTime;
  DateTime? _viewEndTime;

  // PRE-FILTER: Define which series to show by default
  final Set<String> _defaultVisibleSeries = {
    'TAI',
    'TAO',
    'O2',
    'DCFM',
    // Add more series names here as needed
    // 'TAI_1', 'TAI_2', 'TAI_3', 'TAI_4',
    // 'TAO_R1', 'TAO_R2', 'TAO_R3', 'TAO_R4',
  };

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      zoomMode: ZoomMode.x, // Horizontal-only zoom
      enablePanning: true,
      enableSelectionZooming: true,
      enableDoubleTapZooming: true,
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
          _isLoading = false;
        });
        return;
      }

      final List<String> availableColumnNames =
          rawData.isNotEmpty
              ? rawData.first.keys
                  .where((key) => key != 'datetime' && key != 'Date')
                  .toList()
              : [];

      print(
        'DEBUG: All keys in rawData: ${rawData.isNotEmpty ? rawData.first.keys.toList() : []}',
      );
      print('DEBUG: Filtered available columns: $availableColumnNames');

      // Use provided column names, or all available if none provided.
      final List<String> columnNames = widget.columnNames.isNotEmpty
          ? widget.columnNames
          : availableColumnNames;
      print('_loadChartData: Using columns: $columnNames');
      // Use provided column names, or all available if none provided
      final List<String> columnNames =
          widget.columnNames.isNotEmpty
              ? widget.columnNames
                  .where((name) => name != 'Date' && name != 'SMOOTHBYFILTER')
                  .toList()
              : availableColumnNames;

      _availableColumns = columnNames;
      print('_loadChartData: Available columns: $columnNames');

      // Initialize visibility map - apply pre-filtering here
      _seriesVisibility = {};
      for (String column in columnNames) {
        // Check if this series should be visible by default
        _seriesVisibility[column] = _defaultVisibleSeries.contains(column);
      }

      _minX = rawData.isNotEmpty ? rawData.first['datetime'] : null;
      _maxX = rawData.isNotEmpty ? rawData.last['datetime'] : null;
      print('_loadChartData: minX: $_minX, maxX: $_maxX');

      List<LineSeries<ChartDataPoint, DateTime>> lineSeriesList = [];
      List<NumericAxis> secondaryYAxisList = [];
      _yAxisTitle.clear();
      _legendVisibility.clear(); // Clear existing visibility states.
      _legendKeys.clear(); // Clear the legend keys

      for (var columnName in columnNames) {
        final String label =
            widget.headerNameMappings?[columnName] ?? columnName;
        print('_loadChartData: Processing column: $columnName, label: $label');

        List<ChartDataPoint> chartData = rawData.map((item) {
          final dataPoint = ChartDataPoint.fromMap(
            map: item,
            columnName: columnName,
          );
          return dataPoint;
        }).toList();
        print(
            '_loadChartData: Created ${chartData.length} data points for column $columnName');

        if (chartData.isNotEmpty) {
          // Determine min and max for the Y-Axis
          double minY = chartData.first.y;
          double maxY = chartData.first.y;
          for (final dataPoint in chartData) {
            if (dataPoint.y < minY) {
              minY = dataPoint.y;
            }
            if (dataPoint.y > maxY) {
              maxY = dataPoint.y;
            }
          }

          // Create a unique name for the secondary axis.
          String yAxisName = 'yAxis_$columnName';

          // Store the y-axis title
          _yAxisTitle[columnName] = label;
          _legendVisibility[label] =
              true; // Initialize all series as visible.
          _legendKeys.add(
              label); // Store the label.  This is important for the onLegendTapped handler
          final yAxis = NumericAxis(
            name: yAxisName,
            title: AxisTitle(text: label),
            minimum: minY,
            maximum: maxY,
          );

          secondaryYAxisList.add(yAxis);

          lineSeriesList.add(
            LineSeries<ChartDataPoint, DateTime>(
              name: label,
              dataSource: chartData,
              xValueMapper: (ChartDataPoint data, _) => data.x,
              yValueMapper: (ChartDataPoint data, _) => data.y,
              color: _getColorForColumn(columnName),
              markerSettings: const MarkerSettings(isVisible: false),
              yAxisName: yAxisName,
            ),
          );
        } else {
          print(
              '_loadChartData: No data points for column $columnName.  Skipping.');
        }
      }

      // *IMPORTANT*:  Move the setState *inside* the data loading
      setState(() {
        _title = 'Local Data Chart';
        _seriesData = lineSeriesList;
        _secondaryYAxis.clear();
        _secondaryYAxis.addAll(secondaryYAxisList);
        _isLoading = false;
      });
      // No need to call it here.

      // Initialize view to show all data initially
      _viewStartTime = _minX;
      _viewEndTime = _maxX;

      _updateSeries();
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

  void _updateSeries() {
    List<LineSeries<ChartDataPoint, DateTime>> lineSeriesList = [];

    for (var columnName in _availableColumns) {
      // Only add series that are set to visible
      if (_seriesVisibility[columnName] != true) continue;

      final String label = widget.headerNameMappings?[columnName] ?? columnName;
      print(
        '_updateSeries: Processing visible column: $columnName, label: $label',
      );

      List<ChartDataPoint> chartData =
          widget.rawData.map((item) {
            final dataPoint = ChartDataPoint.fromMap(
              map: item,
              columnName: columnName,
            );
            return dataPoint;
          }).toList();

      // Add debug output
      print(
        '_updateSeries: For column $columnName, created ${chartData.length} points',
      );
      if (chartData.isNotEmpty) {
        print('_updateSeries: First few points for $columnName:');
        for (int i = 0; i < 3 && i < chartData.length; i++) {
          print('  Point $i: x=${chartData[i].x}, y=${chartData[i].y}');
        }
      }

      if (chartData.isNotEmpty) {
        lineSeriesList.add(
          LineSeries<ChartDataPoint, DateTime>(
            name: label,
            dataSource: chartData,
            xValueMapper: (ChartDataPoint data, _) => data.x,
            yValueMapper: (ChartDataPoint data, _) => data.y,
            color: _getColorForColumn(columnName),
            markerSettings: const MarkerSettings(isVisible: false),
            // Add a stable key based on column name to prevent animation issues
            key: ValueKey(columnName),
          ),
        );
      }
    }

    setState(() {
      _title = 'Time Series Data (Last 24 Hours)';
      _seriesData = lineSeriesList;
      _isLoading = false;
    });

    print('_updateSeries: Created ${lineSeriesList.length} visible series');
  }

  // Time control methods
  void _setTimeRange(Duration? duration) {
    print('Setting time range to: $duration');

    if (duration == null) {
      // Show all data
      setState(() {
        _currentTimeWindow = const Duration(days: 365);
        _timePosition = 0.0;
        _viewStartTime = _minX;
        _viewEndTime = _maxX;
      });
    } else {
      setState(() {
        _currentTimeWindow = duration;
        _timePosition = 1.0; // Start at the end (most recent data)
        if (_maxX != null) {
          _viewEndTime = _maxX;
          _viewStartTime = _maxX!.subtract(duration);
        }
      });
    }
  }

  void _updateTimeView(double position) {
    print('Time slider moved to position: $position');

    if (_minX == null || _maxX == null) return;

    final totalDuration = _maxX!.difference(_minX!);
    final windowDuration = _currentTimeWindow;

    // Don't allow window larger than total data
    final effectiveWindow =
        windowDuration.inMilliseconds > totalDuration.inMilliseconds
            ? totalDuration
            : windowDuration;

    // Calculate the start time based on slider position
    final maxStartOffset = totalDuration - effectiveWindow;
    final startOffset = Duration(
      milliseconds: (maxStartOffset.inMilliseconds * position).round(),
    );

    setState(() {
      _timePosition = position;
      _viewStartTime = _minX!.add(startOffset);
      _viewEndTime = _viewStartTime!.add(effectiveWindow);
    });
  }

  void _zoomToTimeRange(Duration duration) {
    print('Would zoom to time range: $duration');
    // Simplified - just reset for now
    _zoomPanBehavior.reset();
  }

  void _zoomToDateRange(DateTime startTime, DateTime endTime) {
    print('Would zoom to date range: $startTime - $endTime');
    // Simplified - just reset for now
    _zoomPanBehavior.reset();
  }

  // Series control methods
  void _toggleSeries(String columnName) {
    setState(() {
      _seriesVisibility[columnName] = !(_seriesVisibility[columnName] ?? false);
    });
    _updateSeries();
  }

  void _showAllSeries() {
    setState(() {
      for (String column in _availableColumns) {
        _seriesVisibility[column] = true;
      }
    });
    _updateSeries();
  }

  void _hideAllSeries() {
    setState(() {
      for (String column in _availableColumns) {
        _seriesVisibility[column] = false;
      }
    });
    _updateSeries();
  }

  void _resetToDefaults() {
    setState(() {
      for (String column in _availableColumns) {
        _seriesVisibility[column] = _defaultVisibleSeries.contains(column);
      }
    });
    _updateSeries();
  }

  // Function to select color based on the column name
  Color _getColorForColumn(String columnName) {
    switch (columnName) {
      // Removed .toLowerCase()
      case 'TAI':
        return Colors.blue;
      case 'TAI_1':
        return Colors.green;
      case 'TAI_2':
        return Colors.red;
      case 'TAI_3':
        return Colors.yellow;
      case 'TAI_4':
        return Colors.purple;
      case 'DCFM_SMOOTHBYFILTER':
        return Colors.orange;
      case 'DCFM':
        return Colors.orange; // Added this for your actual column name
      case 'SMOOTHBYFILTER':
        return Colors.deepOrange; // Different shade for this one
      case 'O2':
        return Colors.pink;
      case 'TAO':
        return Colors.teal;
      case 'TAO_R1':
        return Colors.amber;
      case 'TAO_R2':
        return Colors.brown;
      case 'TAO_R3':
        return Colors.cyan;
      case 'TAO_R4':
        return Colors.deepOrange;
      case 'TWI':
        return Colors.deepPurple;
      case 'TWO':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  // UI Widget builders
  Widget _buildTimeControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Time range preset buttons
          const Text(
            'Time Range:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeRangeButton('1 Hour', const Duration(hours: 1)),
                _timeRangeButton('6 Hours', const Duration(hours: 6)),
                _timeRangeButton('12 Hours', const Duration(hours: 12)),
                _timeRangeButton('24 Hours', const Duration(hours: 24)),
                _timeRangeButton('All Data', null),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time navigation slider
          const Text(
            'Navigate Time:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _timePosition,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: (value) {
                print('Slider changed to: $value');
                setState(() {
                  _timePosition = value;
                });
                _updateTimeView(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRangeButton(String label, Duration? duration) {
    // Simplified selection logic
    bool isSelected = false;
    if (duration == null) {
      isSelected = _currentTimeWindow.inDays >= 365; // "All Data"
    } else {
      isSelected = _currentTimeWindow.inHours == duration.inHours;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () {
          print('Time range button pressed: $label');
          _setTimeRange(duration);
        },
        child: Text(label),
      ),
    );
  }

  Widget _buildSeriesFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Series Visibility:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showAllSeries,
                child: const Text('Show All'),
              ),
              TextButton(
                onPressed: _hideAllSeries,
                child: const Text('Hide All'),
              ),
              TextButton(
                onPressed: _resetToDefaults,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                _availableColumns.map((columnName) {
                  final bool isVisible = _seriesVisibility[columnName] ?? false;
                  final String label =
                      widget.headerNameMappings?[columnName] ?? columnName;

                  return FilterChip(
                    label: Text(label),
                    selected: isVisible,
                    onSelected: (bool selected) => _toggleSeries(columnName),
                    selectedColor: _getColorForColumn(
                      columnName,
                    ).withOpacity(0.3),
                    backgroundColor: Colors.grey[200],
                    checkmarkColor: _getColorForColumn(columnName),
                  );
                }).toList(),
          ),
        ],
      ),
    );
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
                    child: SfCartesianChart(
                      key: _chartKey, // Assign the key
                      title: ChartTitle(text: _title),
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      onLegendTapped: (LegendTapArgs args) {
                        // Null check for args.seriesIndex
                        if (args.seriesIndex != null) {
                          String tappedLegendItem =
                              _legendKeys[args.seriesIndex!];
                          print('Tapped legend: $tappedLegendItem');
                          setState(() {
                            _legendVisibility[tappedLegendItem] =
                                !_legendVisibility[tappedLegendItem]!;
                          });
                          // No need to call _updateChart() here.  The setState will trigger a rebuild
                        } else {
                          print('args.seriesIndex is null');
                          // Handle the null case
                        }
                      },
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('yyyy-MM-dd HH:mm:ss'),
                        title: AxisTitle(text: 'Time'),
                      ),
                      primaryYAxis: _getYAxis(), // Use the single Y-axis getter
                      axes: [], //  No secondary axes.
                      series: _getSeriesData(),
                      zoomPanBehavior: _zoomPanBehavior,
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        shared: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  //  Helper Functions
  List<LineSeries<ChartDataPoint, DateTime>> _getSeriesData() {
    return _seriesData.map((series) {
      // Use the visibility state.
      final isVisible = _legendVisibility[series.name] ?? true;
      return LineSeries<ChartDataPoint, DateTime>(
        name: series.name,
        dataSource: series.dataSource,
        xValueMapper: series.xValueMapper,
        yValueMapper: series.yValueMapper,
        color: _getColorForColumn(series.name!),
        opacity: isVisible ? 1 : 0.5,
        markerSettings: const MarkerSettings(isVisible: false),
        yAxisName:
            'primaryYAxis', // All series use the primary Y axis.
      );
    }).toList();
  }

  NumericAxis _getYAxis() {
    // Check if all series are visible
    bool allVisible = true;
    for (bool visibility in _legendVisibility.values) {
      if (!visibility) {
        allVisible = false;
        break;
      }
    }

    if (allVisible) {
      // If all are visible, return an axis with no labels
      return NumericAxis(
        labelStyle: const TextStyle(fontSize: 0),
        majorTickLines: const MajorTickLines(size: 0),
        minorTickLines: const MinorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      );
    } else {
      // Otherwise, return a standard Y axis, with dynamic range.
      double overallMaxY = double.negativeInfinity;
      // Find the maximum Y value across all *visible* series.
      for (final series in _seriesData) {
        if (_legendVisibility[series.name] ??
            true) { // Only consider visible series
          for (final dataPoint in series.dataSource!) {
            if (dataPoint.y > overallMaxY) {
              overallMaxY = dataPoint.y;
            }
          }
          
        }
      }
      // Round up the maximum Y value to the nearest 10.
      overallMaxY = (overallMaxY / 10).ceil() * 10;

      return NumericAxis(
        title: AxisTitle(text: 'Value'),
        minimum: 0, // Fixed minimum
        maximum: overallMaxY, // Dynamic maximum
      );
    }
  }

}

*/
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Time range and navigation controls
        _buildTimeControls(),

        // Series filter panel
        _buildSeriesFilterPanel(),

        // Chart with fixed height that works well
        SizedBox(
          height: 500, // Fixed height that should work on most screens
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
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
              child: SfCartesianChart(
                title: ChartTitle(text: _title),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MM/dd HH:mm'),
                  title: AxisTitle(text: 'Time'),
                  minimum: _viewStartTime,
                  maximum: _viewEndTime,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Value'),
                  minimum: 0,
                  maximum: 200,
                ),
                series: _seriesData,
                zoomPanBehavior: _zoomPanBehavior,
                tooltipBehavior: TooltipBehavior(enable: true, shared: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
