// lib/providers/tab_provider.dart
import 'package:flutter/material.dart';

class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() {
    changeTab(0);
  }

  void goToFavorites() {
    changeTab(1);
  }

  void goToMessages() {
    changeTab(2);
  }

  void goToProfile() {
    changeTab(3);
  }
}