import 'package:flutter/material.dart';
import 'package:agrilab_app/models/user.dart'; // Import the User model

class HomeScreen extends StatelessWidget {
  final User currentUser; // Receive the user object

  HomeScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome, ${currentUser.username}!'), // Display username
      ),
    );
  }
}
