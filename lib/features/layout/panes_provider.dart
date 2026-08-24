import 'package:flutter/material.dart';
import 'package:panes/panes.dart';

class PanesProvider extends ChangeNotifier {
  final IdeController ideController = IdeController(
    leftSize: PaneSize.pixel(200),
    leftMinSize: PaneSize.pixel(120),
    leftMaxSize: PaneSize.pixel(500),
    leftVisible: false,
    rightSize: PaneSize.pixel(260),
    rightMinSize: PaneSize.pixel(120),
    rightMaxSize: PaneSize.pixel(500),
    rightVisible: false,
    bottomSize: PaneSize.pixel(200),
    bottomMinSize: PaneSize.pixel(80),
    bottomMaxSize: PaneSize.pixel(500),
    bottomVisible: false,
  );

  int _selectedSidebarIndex = 0;
  bool _isLeftVisible = false;
  bool _isRightVisible = false;
  bool _isBottomVisible = false;

  int get selectedSidebarIndex => _selectedSidebarIndex;
  bool get isLeftVisible => _isLeftVisible;
  bool get isRightVisible => _isRightVisible;
  bool get isBottomVisible => _isBottomVisible;

  void toggleLeft() {
    ideController.toggleLeft();
    _isLeftVisible = ideController.rootController.isVisible(IdePane.left.id);
    notifyListeners();
  }

  void toggleRight() {
    ideController.toggleRight();
    _isRightVisible = ideController.rootController.isVisible(IdePane.right.id);
    notifyListeners();
  }

  void toggleBottom() {
    ideController.toggleBottom();
    _isBottomVisible = ideController.centerController.isVisible(
      IdePane.bottom.id,
    );
    notifyListeners();
  }

  void onSidebarTabPressed(int index) {
    final leftVisible = ideController.rootController.isVisible(IdePane.left.id);
    if (_selectedSidebarIndex == index && leftVisible) {
      ideController.rootController.hide(IdePane.left.id);
      _isLeftVisible = false;
    } else {
      _selectedSidebarIndex = index;
      if (!leftVisible) {
        ideController.rootController.show(IdePane.left.id);
        _isLeftVisible = true;
      }
    }
    notifyListeners();
  }

  void onPaneVisibilityChanged(IdePane pane, bool visible) {
    if (pane == IdePane.left) {
      _isLeftVisible = visible;
    } else if (pane == IdePane.right) {
      _isRightVisible = visible;
    } else if (pane == IdePane.bottom) {
      _isBottomVisible = visible;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    ideController.dispose();
    super.dispose();
  }
}
