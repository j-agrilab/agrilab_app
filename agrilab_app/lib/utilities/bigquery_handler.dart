/*
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

/// The BigQuery client object. It will be initialized in the fetchBigQueryData function.
BigqueryApi? _bigquery;

/// A helper function that handles the common data processing, sorting,
/// and filtering to the last 24 hours.
Future<List<Map<String, dynamic>>> _processAndFilterData(List<Map<String, dynamic>> rawData) async {
  List<Map<String, dynamic>> allData = [];
  for (var row in rawData) {
    // Find the key for the datetime column. Assumes it's the first one.
    final dateTimeKey = row.keys.first;

    final dynamic rawDateTime = row[dateTimeKey];
    DateTime? parsedDate;
    if (rawDateTime is String) {
      parsedDate = _parseDateTime(rawDateTime);
    } else if (rawDateTime is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDateTime);
    } else if (rawDateTime is double) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDateTime.toInt());
    } else {
      // Skip if datetime cannot be parsed
      continue;
    }
    
    if (parsedDate == null) continue;

    Map<String, dynamic> rowData = {'datetime': parsedDate};

    // Iterate through the rest of the columns
    for (var key in row.keys.skip(1)) {
      final dynamic value = row[key];
      // Handle DCFM_SMOOTHBYFILTER like in the original code
      String finalKey = key;
      if (key == 'DCFM_SMOOTHBYFILTER') {
        finalKey = 'DCFM';
      }
      
      if (value == null) {
        rowData[finalKey] = 0.0;
      } else if (value is num) {
        rowData[finalKey] = value.toDouble();
      } else {
        rowData[finalKey] = double.tryParse(value.toString()) ?? 0.0;
      }
    }
    allData.add(rowData);
  }
  
  // Sort and filter the data to the last 24 hours
  if (allData.isEmpty) {
    print('No valid data found after parsing');
    return [];
  }

  allData.sort(
    (a, b) =>
        (a['datetime'] as DateTime).compareTo(b['datetime'] as DateTime),
  );

  final DateTime maxDate = allData.last['datetime'] as DateTime;
  final DateTime twentyFourHoursAgo = maxDate.subtract(
    const Duration(hours: 24),
  );

  print(
    'Data range: ${allData.first['datetime']} to $maxDate',
  );
  print(
    'Filtering to show data from $twentyFourHoursAgo onwards',
  );

  final List<Map<String, dynamic>> filteredData =
      allData.where((row) {
        final DateTime rowDate = row['datetime'] as DateTime;
        return rowDate.isAfter(twentyFourHoursAgo) ||
            rowDate.isAtSameMomentAs(twentyFourHoursAgo);
      }).toList();

  print(
    'Parsed ${filteredData.length} data points from last 24 hours (out of ${allData.length} total)',
  );
  if (filteredData.isNotEmpty) {
    print(
      'Filtered range: ${filteredData.first['datetime']} to ${filteredData.last['datetime']}',
    );
  }

  return filteredData;
}

/// Executes a custom SQL query on a BigQuery table and returns the processed data.
Future<List<Map<String, dynamic>>> queryBigQueryData({
  required String projectId,
  required String query,
}) async {
  // Authentication: In a production Flutter app, credentials should be
  // handled securely on a backend server or via a Google Cloud Function
  // to avoid exposing them client-side.
  // For this example, we assume `getCredentials` is implemented securely.
  // Replace the placeholder with your actual authenticated client.
  final client = await getCredentials(); // Placeholder for your authentication logic
  _bigquery = BigqueryApi(client);
  print('queryBigQueryData: Starting data retrieval...');
  try {
    List<Map<String, dynamic>> rawData = [];
    final QueryRequest queryRequest = QueryRequest(query: query);
    final queryResponse = await _bigquery!.jobs.query(queryRequest, projectId);
    
    if (queryResponse.jobComplete != true || queryResponse.rows == null) {
      throw Exception("BigQuery job not complete or returned no data.");
    }
    // Process the rows from the query result
    for (var row in queryResponse.rows!) {
      Map<String, dynamic> rowData = {};
      if (row.f != null) {
        // Use the schema from the query response to get column names
        final headers = queryResponse.schema?.fields?.map((f) => f.name).toList() ?? [];
        for (var i = 0; i < row.f!.length; i++) {
          final header = headers.length > i ? headers[i] : 'column_$i';
          final value = row.f![i].v;
          rowData[header] = value;
        }
        rawData.add(rowData);
      }
    }
    return _processAndFilterData(rawData);
  } catch (e) {
    print('queryBigQueryData: Error fetching from BigQuery: $e');
    return [];
  }
}

/// Fetches all data from a specified BigQuery table and returns the processed data.
///
/// Note: This is not scalable for very large tables.
Future<List<Map<String, dynamic>>> pullAllTableData({
  required String projectId,
  required String datasetId,
  required String tableId,
}) async {
  // Authentication: In a production Flutter app, credentials should be
  // handled securely on a backend server or via a Google Cloud Function
  // to avoid exposing them client-side.
  // For this example, we assume `getCredentials` is implemented securely.
  // Replace the placeholder with your actual authenticated client.
  final client = await getCredentials(); // Placeholder for your authentication logic
  _bigquery = BigqueryApi(client);
  print('pullAllTableData: Starting data retrieval...');

  try {
    List<Map<String, dynamic>> rawData = [];
    final tableData = await _bigquery!.tabledata.list(projectId, datasetId, tableId);
    
    if (tableData.rows != null) {
      // Find the actual headers from the table schema
      final table = await _bigquery!.tables.get(projectId, datasetId, tableId);
      final headers = table.schema?.fields?.map((f) => f.name).toList() ?? [];

      for (var row in tableData.rows!) {
        Map<String, dynamic> rowData = {};
        if (row.f != null) {
          for (var i = 0; i < row.f!.length; i++) {
            final header = headers.length > i ? headers[i] : 'column_$i';
            final value = row.f![i].v;
            rowData[header] = value;
          }
          rawData.add(rowData);
        }
      }
    }
    return _processAndFilterData(rawData);
  } catch (e) {
    print('pullAllTableData: Error fetching from BigQuery: $e');
    return [];
  }
}

// Helper function to parse different datetime formats.
DateTime? _parseDateTime(String dateTimeStr) {
  final List<String> formats = [
    'HH:mm:ss MM-dd-yyyy', // 23:55:43 03-09-2025
    'yyyy-MM-dd HH:mm:ss', // 2025-03-09 23:55:43
    'MM/dd/yyyy HH:mm:ss', // 03/09/2025 23:55:43
  ];

  for (String format in formats) {
    try {
      if (format == 'HH:mm:ss MM-dd-yyyy') {
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final datePart = parts[1];

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
        final DateFormat formatter = DateFormat(format);
        return formatter.parse(dateTimeStr);
      }
    } catch (e) {
      continue;
    }
  }

  return null;

*/