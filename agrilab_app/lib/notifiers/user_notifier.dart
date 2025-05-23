import 'package:flutter/foundation.dart';
import 'package:agrilab_app/models/user.dart';

// This isn't used but might end up using it
class UserNotifier extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }
}