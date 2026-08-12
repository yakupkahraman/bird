import 'dart:io';
import 'package:bird/providers/lsp_provider.dart';
import 'package:bird/providers/prog_lang_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileProvider extends ChangeNotifier {
  String? _rootPath;
  List<FileSystemEntity> _files = [];

  final List<String> _openFilePaths = [];
  final Map<String, CodeForgeController> _controllers = {};
  String? _selectedFilePath;

  final Set<String> _expandedPaths = {};

  LspProvider? _lsp;

  String? get rootPath => _rootPath;
  List<FileSystemEntity> get files => _files;
  List<String> get openFilePaths => List.unmodifiable(_openFilePaths);
  String? get selectedFilePath => _selectedFilePath;

  CodeForgeController get currentController {
    if (_selectedFilePath != null &&
        _controllers.containsKey(_selectedFilePath)) {
      return _controllers[_selectedFilePath]!;
    }
    return _defaultController;
  }

  final CodeForgeController _defaultController = CodeForgeController();

  /// Called from `ChangeNotifierProxyProvider` on every build, so it must be
  /// idempotent.
  void attachLsp(LspProvider lsp) {
    if (identical(_lsp, lsp)) return;
    _lsp?.removeListener(_rebindControllers);
    _lsp = lsp;
    lsp.addListener(_rebindControllers);
  }

  /// Re-creates controllers so files opened before the language server was
  /// ready still get it. `lspConfig` is final on the controller, so there is no
  /// way to swap it in place; the text is carried over.
  void _rebindControllers() {
    var changed = false;
    for (final path in _openFilePaths) {
      final config = _lsp?.getLspConfigForFile(path);
      final current = _controllers[path]!;
      if (identical(current.lspConfig, config)) continue;

      final text = current.text;
      current.dispose();
      _controllers[path] = CodeForgeController(lspConfig: config)..text = text;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  bool isExpanded(String path) => _expandedPaths.contains(path);

  void toggleExpanded(String path) {
    if (_expandedPaths.contains(path)) {
      _expandedPaths.remove(path);
    } else {
      _expandedPaths.add(path);
    }
    notifyListeners();
  }

  Future<void> pickFolder() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    if (selectedDirectory != _rootPath) {
      // Tabs belong to the old workspace, and their controllers would keep
      // talking to a language server we are about to kill.
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _openFilePaths.clear();
      _selectedFilePath = null;
    }

    _rootPath = selectedDirectory;
    _expandedPaths.clear();

    final dir = Directory(selectedDirectory);
    _files = dir.listSync();
    _sortFiles(_files);

    // Show the tree right away; let the language server boot in background.
    notifyListeners();

    await _lsp?.updateWorkspace(selectedDirectory);
  }

  void _sortFiles(List<FileSystemEntity> fileList) {
    fileList.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
  }

  Future<void> openFile(
    String path, [
    ProgLangProvider? languageProvider,
  ]) async {
    try {
      if (!_openFilePaths.contains(path)) {
        final content = await File(path).readAsString();

        // The file may have been clicked again while we were reading it.
        if (!_openFilePaths.contains(path)) {
          _controllers[path] = CodeForgeController(
            lspConfig: _lsp?.getLspConfigForFile(path),
          )..text = content;
          _openFilePaths.add(path);
        }
      }

      _selectedFilePath = path;
      languageProvider?.trySetLanguageByFilePath(path);
      notifyListeners();
    } catch (e) {
      debugPrint("Dosya okuma hatası: $e");
    }
  }

  void selectTab(String path, [ProgLangProvider? languageProvider]) {
    if (_openFilePaths.contains(path)) {
      _selectedFilePath = path;
      languageProvider?.trySetLanguageByFilePath(path);
      notifyListeners();
    }
  }

  void closeTab(String path) {
    final index = _openFilePaths.indexOf(path);
    if (index != -1) {
      _openFilePaths.removeAt(index);
      final controller = _controllers.remove(path);
      if (controller != null) {
        // dispose() does not send didClose, so the server would keep the file
        // and its unsaved edits in its analysis set.
        controller.lspConfig?.closeDocument(path);
        controller.dispose();
      }

      if (_selectedFilePath == path) {
        if (_openFilePaths.isNotEmpty) {
          final newIndex = index.clamp(0, _openFilePaths.length - 1);
          _selectedFilePath = _openFilePaths[newIndex];
        } else {
          _selectedFilePath = null;
        }
      }
      notifyListeners();
    }
  }

  Future<void> saveFile() async {
    if (_selectedFilePath == null) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Yeni Dosya Kaydet',
        fileName: 'new_chick.txt',
        allowedExtensions: ['txt'],
        type: FileType.custom,
      );

      if (outputFile == null) return;
      _selectedFilePath = outputFile;
      _openFilePaths.add(outputFile);
      _controllers[outputFile] = CodeForgeController();
    }

    try {
      final file = File(_selectedFilePath!);
      final controller = currentController;
      await file.writeAsString(controller.text);

      if (_rootPath != null) {
        final dir = Directory(_rootPath!);
        _files = dir.listSync();
        _sortFiles(_files);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Dosya kaydetme hatası: $e");
    }
  }

  @override
  void dispose() {
    _lsp?.removeListener(_rebindControllers);
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _defaultController.dispose();
    super.dispose();
  }
}
