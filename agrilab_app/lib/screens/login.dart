import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrilab_app/models/user.dart';
import 'package:agrilab_app/notifiers/user_notifier.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:agrilab_app/screens/home.dart';
import 'dart:convert';


// The GoogleSignIn instance that will handle authentication
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/cloud-platform',
  ],
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleGoogleSignIn(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // Simulate authentication logic (replace with actual authentication)
      // In this example, we assume successful login and set the user using userNotifier
      User user = User(username: username);

      // Navigate to the home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(currentUser: user),
        ),
      );

      // Now, after the navigation is complete, you can safely call setState
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;
      // TODO: add logic to check if username is taken


      // Simulate authentication logic (replace with actual authentication)
      // In this example, we assume successful login and set the user using userNotifier
      User user = User(username: username);

      // TODO: Replace HomePage with RegistrationPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(currentUser: user),
        ),
      );

      // Now, after the navigation is complete, you can safely call setState
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _signIn.signIn();
      if (googleUser == null) {
        // The user cancelled the sign-in.
        throw Exception('Sign-in process cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google Sign-In.');
      }
      
      // Now, call your backend endpoint and pass the ID token.
      final response = await http.post(
        Uri.parse('https://auth-service-261960905982.us-central1.run.app/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        // You can add a request body if your backend requires it
        body: jsonEncode({
          'user_email': googleUser.email,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful. Navigate to the Home Screen.
        // Replace this with your actual user model
        final user = User(username: googleUser.email);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(currentUser: user),
          ),
        );
      } else {
        // The backend rejected the token or returned an error.
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (e) {
      print('Sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}