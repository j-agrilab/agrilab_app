// lib/services/mock_bigquery_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/chart_data.dart';
import 'package:flutter/services.dart'; // Import for rootBundle

class MockBigQueryService {
  Future<List<ChartData>> fetchData({
    required String tableId,
    required String queryString,
    String? filePath, // Add an optional file path parameter
  }) async {
    try {
      String rawData;
      if (filePath != null) {
        // Read from a local file if filePath is provided
        final file = File(filePath);
        rawData = await file.readAsString();
      } else {
        rawData = await rootBundle.loadString('local_data/my_test_data.csv');
      }

      final List<List<dynamic>> records =
          const CsvToListConverter().convert(rawData);

      if (records.isEmpty) {
        return [];
      }

      // Assuming the first row is the header
      final header = records.first.map((h) => h.toString().toLowerCase()).toList();
      final List<Map<String, dynamic>> data = [];

      for (int i = 1; i < records.length; i++) {
        final row = records[i];
        final entry = <String, dynamic>{};
        for (int j = 0; j < header.length && j < row.length; j++) {
          entry[header[j]] = row[j];
        }
        data.add(entry);
      }

      // Convert the parsed data into ChartData objects
      List<ChartData> chartDataList = data.map((row) {
        // Find a date column, if available.
        String? dateString;
        if (row.containsKey('date')) {
          dateString = row['date'];
        } else if (row.containsKey('time')) {
          dateString = row['time'];
        } else {
          // If no date column is found, use a default date, or the first column
          dateString = '2024-01-01'; // Default
          if(row.isNotEmpty){
             dateString = row.values.first.toString();
          }
        }
        DateTime parsedDate;
        try{
          parsedDate = DateTime.parse(dateString!);
        } catch (e){
          parsedDate = DateTime(2024,1,1);
        }


        return ChartData(
          parsedDate: parsedDate,
          data: row,
        );
      }).toList();
      return chartDataList;
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }
}