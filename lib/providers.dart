import 'package:flutter/material.dart';

class UserCoice with ChangeNotifier {
  bool _isMenuExpandedTrue = true;

  bool get isMenuExpandedTrue => _isMenuExpandedTrue;

  void ToggleMenu() {
    _isMenuExpandedTrue = !_isMenuExpandedTrue;
    notifyListeners(); // Notifies listeners when the value changes
  }
}
