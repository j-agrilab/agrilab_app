// widgets/google_sign_in_button.dart
import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool isSigningIn;
  final VoidCallback onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isSigningIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isSigningIn ? null : onPressed,
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24,
      ),
      label: Text(
        isSigningIn ? 'Signing in with Google...' : 'Sign in with Google',
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}