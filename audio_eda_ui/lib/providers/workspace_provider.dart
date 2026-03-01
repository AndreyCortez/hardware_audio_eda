import 'package:flutter/material.dart';

class WorkspaceProvider extends ChangeNotifier {
  int _activeSidebarIndex = 0;
  bool _isSidebarOpen = true;
  bool _isBottomPanelOpen = true;
  bool _isRightPanelOpen = true;

  int get activeSidebarIndex => _activeSidebarIndex;
  bool get isSidebarOpen => _isSidebarOpen;
  bool get isBottomPanelOpen => _isBottomPanelOpen;
  bool get isRightPanelOpen => _isRightPanelOpen;

  void setActiveSidebarIndex(int index) {
    if (_activeSidebarIndex == index) {
      _isSidebarOpen = !_isSidebarOpen;
    } else {
      _activeSidebarIndex = index;
      _isSidebarOpen = true;
    }
    notifyListeners();
  }

  void toggleBottomPanel() {
    _isBottomPanelOpen = !_isBottomPanelOpen;
    notifyListeners();
  }

  void toggleRightPanel() {
    _isRightPanelOpen = !_isRightPanelOpen;
    notifyListeners();
  }

  void setRightPanelOpen(bool open) {
    _isRightPanelOpen = open;
    notifyListeners();
  }
}
