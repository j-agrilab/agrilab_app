import 'package:flutter/material.dart';
import 'package:agrilab_app/screens/local_data_chart_screen.dart'; // Import the LocalDataChartScreen
import 'package:path_provider/path_provider.dart';

void main() {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart Test App',
      home: const ChartTestScreen(), // Use a separate StatefulWidget
    );
  }
}

class ChartTestScreen extends StatelessWidget {
  const ChartTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocalDataChartScreen(
                  filePath:
                      'lib/assets/local_data/WSWMD_Trends-1m_Trends_1m__Trends-1m_Trends_1m_250309.csv',
                  columnNames: [
                    'tai',
                    'tai_1',
                    'tai_2',
                    'tai_3',
                    'tai_4',
                    'dcfm',
                    'smoothbyfilter',
                    'o2',
                    'tao',
                    'tao_r1',
                    'tao_r2',
                    'tao_r3',
                    'tao_r4',
                    'twi',
                    'two'
                  ],
                ),
              ),
            );
          },
          child: const Text('Show Chart'),
        ),
      ),
    );
  }
}





/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/bigquery_chart_screen.dart';
import 'screens/sign_in_screen.dart'; // Import the sign-in screen
import 'providers/auth_state.dart'; // Import AuthState

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState()..loadAuthToken(), // Initialize AuthState and load token
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BigQuery Chart App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<AuthState>(
        builder: (context, authState, _) {
          if (authState.isAuthenticated) {
            return const BigQueryChartScreen(
              columnNames: [
                'TW_HOTBOXLOOP',
                'TW_LEFT_RET',
                'TW_RIGHT_RET',
                'TW_GH_RET',
                'TW_SHOP_RET',
                'QW_HOTBOXLOOP',
                'PANEL_TEMP',
                'PANEL_RH',
              ],
            );
          } else {
            return const SignInScreen();
          }
        },
      ),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const BigQueryChartScreen(
              columnNames: [
                'TW_HOTBOXLOOP',
                'TW_LEFT_RET',
                'TW_RIGHT_RET',
                'TW_GH_RET',
                'TW_SHOP_RET',
                'QW_HOTBOXLOOP',
                'PANEL_TEMP',
                'PANEL_RH',
              ],
            ),
      },
    );
  }
}
*/
