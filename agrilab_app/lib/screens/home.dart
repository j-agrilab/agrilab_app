import 'package:flutter/material.dart';
import 'package:agrilab_app/models/user.dart'; // Import the User model
import 'package:agrilab_app/utilities/parse_local_csv.dart'; // Import the parseLocalCSV function
import 'package:agrilab_app/widgets/chart.dart'; // Import the ChartScreen widget
//import 'package:agrilab_app/models/chart_data_point.dart'; // Import the ChartDataPoint model // Unused import
//import 'package:syncfusion_flutter_charts/charts.dart'; // No longer used directly
//import 'package:intl/intl.dart';  // No longer used directly
//import 'package:flutter/services.dart'; // Import for rootBundle // No longer used directly
//import 'package:csv/csv.dart'; // No longer used directly

class HomeScreen extends StatelessWidget {
  final User currentUser; // Receive the user object

  HomeScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Welcome, ${currentUser.username}!'), // Display username
            const SizedBox(height: 20),
            // Use FutureBuilder to handle the asynchronous operation of loading data for the chart.
            FutureBuilder<List<Map<String, dynamic>>>(
              // Use FutureBuilder to handle the asynchronous operation
              future: parseLocalCSV(
                  'lib/assets/data/bquxjob_72d2de2_1964f8a64a8.csv'), // Path to your CSV file.  Make sure this is correct.
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  // Show a loading indicator while the data is being fetched
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  // Show an error message if something went wrong
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  // If the data is loaded successfully, pass it to the ChartScreen
                  final rawData = snapshot.data!;
                  return ChartScreen(
                    rawData: rawData,
                    columnNames: [
                      'Date',
                      'TAI',
                      'TAI_1',
                      'TAI_2',
                      'TAI_3',
                      'TAI_4',
                      'DCFM',
                      'SMOOTHBYFILTER',
                      'O2',
                      'TAO',
                      'TAO_R1',
                      'TAO_R2',
                      'TAO_R3',
                      'TAO_R4',
                      'TWI',
                      'TWO'
                    ],
                    headerNameMappings: {
                      'TAI': 'TAI',
                      'TAI_1': 'TAI_1',
                      'TAI_2': 'TAI_2',
                      'TAI_3': 'TAI_3',
                      'TAI_4': 'TAI_4',
                      'DCFM': 'DCFM',
                      'SMOOTHBYFILTER': 'SmoothByFilter',
                      'O2': 'O2',
                      'TAO': 'TAO',
                      'TAO_R1': 'TAO_R1',
                      'TAO_R2': 'TAO_R2',
                      'TAO_R3': 'TAO_R3',
                      'TAO_R4': 'TAO_R4',
                      'TWI': 'TWI',
                      'TWO': 'TWO'
                    },
                  );
                } else {
                  // This should not happen, but provide a default return
                  return const Center(
                    child: Text('No data available.'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
