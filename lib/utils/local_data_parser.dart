// lib/utils/local_data_parser.dart
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

Future<List<Map<String, dynamic>>> parseLocalCSV(String filePath) async {
  try {
    final rawData = await rootBundle.loadString('local_data/$filePath');
    final List<List<dynamic>> records = const CsvToListConverter().convert(rawData);

    if (records.isEmpty) {
      return [];
    }

    final header = records.first.map((h) => h.toString().toLowerCase()).toList();
    final data = <Map<String, dynamic>>[];

    for (int i = 1; i < records.length; i++) {
      final row = records[i];
      final entry = <String, dynamic>{};
      for (int j = 0; j < header.length && j < row.length; j++) {
        entry[header[j]] = row[j];
      }
      data.add(entry);
    }
    return data;
  } catch (e) {
    print('Error parsing CSV file $filePath: $e');
    return [];
  }
}