import 'package:flutter/material.dart';
import 'package:agrilab_app/screens/login.dart';
import 'package:agrilab_app/screens/chart_viewer.dart';
import 'package:agrilab_app/screens/home.dart';


class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Wait for 3 seconds and then navigate to the home page
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
                'lib/assets/AGT Logo.webp',
                height: 200,
            )
          ],
        ),
      ),
    );
  }
}