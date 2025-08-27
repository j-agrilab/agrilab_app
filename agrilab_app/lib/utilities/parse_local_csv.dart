import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// Import the ChartDataPoint class

// --- Utility function to parse local CSV data ---
Future<List<Map<String, dynamic>>> parseLocalCSV(String filePath) async {
  try {
    print('parseLocalCSV: Loading CSV file from $filePath');
    // Use rootBundle to load from assets
    final rawData = await rootBundle.loadString(filePath);
    //print('parseLocalCSV: File contents:\n$rawData\nprintedrawdata'); // ADDED: Print raw data

    final List<List<dynamic>> records =
        const CsvToListConverter(eol: '\n').convert(rawData);
    
    print('records: $records');

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
        // Parse the date using the month-first format "MM-dd-yyyy"
        dateTime = DateFormat("HH:mm:ss MM-dd-yyyy").parse(row[0]);
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
          // Important: Convert the row value to the correct type (double, in this case)
          final value = double.tryParse(row[j]?.toString() ??
              ''); // Handle null or non-numeric strings
          if (value != null) {
            entry[columnName] = value;
          } else {
            print(
                'parseLocalCSV: Warning: Could not parse value "${row[j]}" for column "$columnName" in row $i.  Skipping this value.');
            // Don't add to entry if it can't be parsed.
          }
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