import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserCoice with ChangeNotifier {
  bool _isMenuExpandedTrue = false;
  bool _isDarkMode = false;
  bool _autoSync = false;

  bool get isMenuExpandedTrue => _isMenuExpandedTrue;
  bool get isDarkMode => _isDarkMode;
  bool get autoSync => _autoSync;
  void setdarkMode(bool value) {
    _isDarkMode = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', _isDarkMode);
    });
    notifyListeners();
  }

  void setautoSync(bool value) {
    _autoSync = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('autoSync', _autoSync);
    });
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notifies listeners when the value changes
  }

  void toggleMenu() {
    _isMenuExpandedTrue = !_isMenuExpandedTrue;
    notifyListeners(); // Notifies listeners when the value changes
  }
}

class ClassPageValues with ChangeNotifier {
  bool _showGradeCard = false;
  List<Map<String, dynamic>> _studentsListToShow = [];

  bool get showGradeCard => _showGradeCard;
  List<Map<String, dynamic>> get studentsListToShow => _studentsListToShow;

  void setStudentsListToShow(List<Map<String, dynamic>> value) {
    _studentsListToShow = value;
    notifyListeners();
  }

  void removeStudentFromList(String studentId) {
    // Create a mutable copy if needed
    _studentsListToShow = List<Map<String, dynamic>>.from(_studentsListToShow);
    _studentsListToShow.removeWhere((student) => student['id'] == studentId);
    notifyListeners();
  }

  void setShowGradeCard(bool value) {
    _showGradeCard = value;
    notifyListeners();
  }
}
