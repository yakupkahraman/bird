import 'package:bird/features/layout/side_panels.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
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

  WorkspaceProvider? _workspace;
  String? _root;

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

  void attachWorkspace(WorkspaceProvider workspace) {
    if (identical(_workspace, workspace)) return;
    _workspace?.removeListener(_onWorkspaceChanged);
    _workspace = workspace..addListener(_onWorkspaceChanged);
    _onWorkspaceChanged();
  }

  // A listener rather than the proxy's update, which runs mid-build where
  // notifying is not allowed.
  void _onWorkspaceChanged() {
    final root = _workspace!.rootPath;
    if (root == _root) return;
    _root = root;
    if (root != null) showSidebar(SidePanels.all.indexOf(SidePanels.explorer));
  }

  /// Opens the sidebar on [index]. Unlike a press on its button, never closes
  /// it.
  void showSidebar(int index) {
    _selectedSidebarIndex = index;
    if (!ideController.rootController.isVisible(IdePane.left.id)) {
      ideController.rootController.show(IdePane.left.id);
      _isLeftVisible = true;
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
    _workspace?.removeListener(_onWorkspaceChanged);
    ideController.dispose();
    super.dispose();
  }
}
