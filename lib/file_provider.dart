import 'dart:io';
import 'package:bird/planguage_provider.dart';
import 'package:code_forge/code_forge/controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileProvider extends ChangeNotifier {
  String? _rootPath;
  List<FileSystemEntity> _files = [];

  final List<String> _openFilePaths = [];
  final Map<String, CodeForgeController> _controllers = {};
  String? _selectedFilePath;

  final Set<String> _expandedPaths = {};

  String? get rootPath => _rootPath;
  List<FileSystemEntity> get files => _files;
  List<String> get openFilePaths => List.unmodifiable(_openFilePaths);
  String? get selectedFilePath => _selectedFilePath;

  CodeForgeController get currentController {
    if (_selectedFilePath != null && _controllers.containsKey(_selectedFilePath)) {
      return _controllers[_selectedFilePath]!;
    }
    return _defaultController;
  }

  final CodeForgeController _defaultController = CodeForgeController();

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
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _rootPath = selectedDirectory;
      _expandedPaths.clear();

      final dir = Directory(selectedDirectory);
      _files = dir.listSync();
      _sortFiles(_files);

      notifyListeners();
    }
  }

  void _sortFiles(List<FileSystemEntity> fileList) {
    fileList.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
  }

  Future<void> openFile(String path, [PlanguageProvider? languageProvider]) async {
    try {
      if (!_openFilePaths.contains(path)) {
        final file = File(path);
        final content = await file.readAsString();
        final controller = CodeForgeController();
        controller.text = content;
        _controllers[path] = controller;
        _openFilePaths.add(path);
      }

      _selectedFilePath = path;
      languageProvider?.trySetLanguageByFilePath(path);
      notifyListeners();
    } catch (e) {
      debugPrint("Dosya okuma hatası: $e");
    }
  }

  void selectTab(String path, [PlanguageProvider? languageProvider]) {
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
      controller?.dispose();

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
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _defaultController.dispose();
    super.dispose();
  }
}
