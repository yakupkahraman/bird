import 'dart:io';
import 'package:code_forge/code_forge/controller.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileProvider extends ChangeNotifier {
  final CodeForgeController controller = CodeForgeController();

  String? _rootPath;
  List<FileSystemEntity> _files = [];
  String? _selectedFilePath;
  String _fileContent = "";

  final Set<String> _expandedPaths = {};

  String? get rootPath => _rootPath;
  List<FileSystemEntity> get files => _files;
  String? get selectedFilePath => _selectedFilePath;
  String get fileContent => _fileContent;

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

  Future<void> openFile(String path) async {
    try {
      final file = File(path);
      _fileContent = await file.readAsString();

      _selectedFilePath = path;
      controller.text = _fileContent;

      notifyListeners();
    } catch (e) {
      debugPrint("Dosya okuma hatası: $e");
    }
  }

  Future<void> saveFile() async {
    if (_selectedFilePath == null) return;

    try {
      final file = File(_selectedFilePath!);
      await file.writeAsString(controller.text);
      print("Dosya başarıyla kaydedildi: $_selectedFilePath");

      notifyListeners();
    } catch (e) {
      debugPrint("Dosya kaydetme hatası: $e");
    }
  }
}
