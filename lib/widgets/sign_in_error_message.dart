// widgets/sign_in_error_message.dart
import 'package:flutter/material.dart';

class SignInErrorMessage extends StatelessWidget {
  final String? errorMessage;

  const SignInErrorMessage({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return const SizedBox.shrink(); // Or an empty Container
  }
}