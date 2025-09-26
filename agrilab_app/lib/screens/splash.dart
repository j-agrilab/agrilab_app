import 'package:flutter/material.dart';
import 'package:agrilab_app/screens/login.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showDatasetSelection = false;

  @override
  void initState() {
    super.initState();
    // Show logo for 3 seconds, then show dataset selection
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _showDatasetSelection = true;
      });
    });
  }

  void _selectDataset(String datasetName) {
    print('Selected dataset: $datasetName');
    // For now, just navigate to login normally
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child:
            _showDatasetSelection
                ? _buildDatasetSelection()
                : _buildSplashContent(),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset('lib/assets/AGT Logo.webp', height: 200),
        SizedBox(height: 30),
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Loading...'),
      ],
    );
  }

  Widget _buildDatasetSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset('lib/assets/AGT Logo.webp', height: 150),
        SizedBox(height: 40),
        Text(
          'Select Dataset',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 40),

        _buildDatasetCard('Country Oaks'),
        _buildDatasetCard('WSWMD'),
      ],
    );
  }

  Widget _buildDatasetCard(String datasetName) {
    return Container(
      width: 300,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: InkWell(
          onTap: () => _selectDataset(datasetName),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.analytics, size: 48, color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  datasetName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
