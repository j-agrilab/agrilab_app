import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

Future<List<Map<String, dynamic>>> parseLocalCSV(String filePath) async {
  try {
    print('parseLocalCSV: Loading CSV from $filePath');

    final String csvString = await rootBundle.loadString(filePath);
    final List<List<dynamic>> csvData = const CsvToListConverter().convert(
      csvString,
    );

    if (csvData.isEmpty) {
      print('parseLocalCSV: No data found in CSV');
      return [];
    }

    final List<dynamic> headers = csvData[0];

    // DEBUG: Let's see what the headers actually are
    print('DEBUG CSV: Headers are: $headers');
    print('DEBUG CSV: Header[0] = ${headers[0]}');
    if (headers.length > 1) print('DEBUG CSV: Header[1] = ${headers[1]}');
    if (headers.length > 2) print('DEBUG CSV: Header[2] = ${headers[2]}');
    if (headers.length > 3) print('DEBUG CSV: Header[3] = ${headers[3]}');

    List<Map<String, dynamic>> allData = [];

    // First, parse all data to find the actual date range
    for (int i = 1; i < csvData.length; i++) {
      final List<dynamic> row = csvData[i];

      if (row.length != headers.length) continue;

      final DateTime? parsedDate = _parseDateTime(row[0].toString());
      if (parsedDate == null) continue;

      Map<String, dynamic> rowData = {'datetime': parsedDate};

      for (int j = 1; j < headers.length; j++) {
        final String header = headers[j].toString();
        // Skip the Date column since we already have datetime
        if (header == 'Date') continue;

        final dynamic value = row[j];

        // Map DCFM_SMOOTHBYFILTER to just DCFM
        String finalHeader = header;
        if (header == 'DCFM_SMOOTHBYFILTER') {
          finalHeader = 'DCFM';
          print(
            'DEBUG: Mapping $header to $finalHeader, value: $value',
          ); // Add this debug line
        }

        // Add debug for all headers in first few rows
        if (i <= 3) {
          print(
            'DEBUG: Row $i, header: "$header" -> "$finalHeader", value: $value',
          );
        }

        if (value == null || value.toString().isEmpty) {
          rowData[finalHeader] = 0.0;
        } else if (value is num) {
          rowData[finalHeader] = value.toDouble();
        } else {
          rowData[finalHeader] = double.tryParse(value.toString()) ?? 0.0;
        }
      }

      allData.add(rowData);
    }

    if (allData.isEmpty) {
      print('parseLocalCSV: No valid data found');
      return [];
    }

    // Sort by datetime to ensure chronological order
    allData.sort(
      (a, b) =>
          (a['datetime'] as DateTime).compareTo(b['datetime'] as DateTime),
    );

    // Find the most recent timestamp in the data
    final DateTime maxDate = allData.last['datetime'] as DateTime;
    final DateTime twentyFourHoursAgo = maxDate.subtract(
      const Duration(hours: 24),
    );

    print(
      'parseLocalCSV: Data range: ${allData.first['datetime']} to $maxDate',
    );
    print(
      'parseLocalCSV: Filtering to show data from $twentyFourHoursAgo onwards',
    );

    // Filter to last 24 hours based on the data's own timeline
    final List<Map<String, dynamic>> filteredData =
        allData.where((row) {
          final DateTime rowDate = row['datetime'] as DateTime;
          return rowDate.isAfter(twentyFourHoursAgo) ||
              rowDate.isAtSameMomentAs(twentyFourHoursAgo);
        }).toList();

    print(
      'parseLocalCSV: Parsed ${filteredData.length} data points from last 24 hours (out of ${allData.length} total)',
    );
    if (filteredData.isNotEmpty) {
      print(
        'parseLocalCSV: Filtered range: ${filteredData.first['datetime']} to ${filteredData.last['datetime']}',
      );
    }

    return filteredData;
  } catch (e) {
    print('parseLocalCSV: Error: $e');
    return [];
  }
}

// Helper function to parse different datetime formats
DateTime? _parseDateTime(String dateTimeStr) {
  // Try different formats based on what I saw in your debug output
  final List<String> formats = [
    'HH:mm:ss MM-dd-yyyy', // 23:55:43 03-09-2025
    'yyyy-MM-dd HH:mm:ss', // 2025-03-09 23:55:43
    'MM/dd/yyyy HH:mm:ss', // 03/09/2025 23:55:43
  ];

  for (String format in formats) {
    try {
      if (format == 'HH:mm:ss MM-dd-yyyy') {
        // Custom parsing for your specific format
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0]; // HH:mm:ss
          final datePart = parts[1]; // MM-dd-yyyy

          final dateParts = datePart.split('-');
          final timeParts = timePart.split(':');

          if (dateParts.length == 3 && timeParts.length == 3) {
            final year = int.parse(dateParts[2]);
            final month = int.parse(dateParts[0]);
            final day = int.parse(dateParts[1]);
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final second = int.parse(timeParts[2]);

            return DateTime(year, month, day, hour, minute, second);
          }
        }
      } else {
        // Try using intl DateFormat for other formats
        final DateFormat formatter = DateFormat(format);
        return formatter.parse(dateTimeStr);
      }
    } catch (e) {
      // Try next format
      continue;
    }
  }

  return null;
}
