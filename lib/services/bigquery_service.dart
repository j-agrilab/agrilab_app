import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chart_data.dart';
import '../constants/api_constants.dart';

class BigQueryService {
  Future<List<ChartData>> fetchData({
    required String tableId,
    required String queryString,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(QUERY_BIGQUERY_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table_id': tableId,
          'query_string': queryString,
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => ChartData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}