class ChartData {
  final DateTime parsedDate;
  final Map<String, dynamic> data;

  ChartData({
    required this.parsedDate,
    required this.data,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      parsedDate: DateTime.parse(json['parsed_date'].toString()),
      data: json,
    );
  }
}