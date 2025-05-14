import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrilab_app/models/user.dart';
import 'package:agrilab_app/notifiers/user_notifier.dart';
import 'package:agrilab_app/screens/home.dart';

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
          child: Form(

            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).nextFocus(); // Move focus to the next field
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _handleLogin(context); // Call the login function when the password field is submitted
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleLogin(context),
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Login'),
                ),
                SizedBox(height: 8.0), // Add some spacing between the login and register buttons
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleRegister(context),
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Register'),
                ),
              ],
            ),
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
}