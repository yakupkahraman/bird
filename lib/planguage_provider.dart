import 'package:flutter/material.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/re_highlight.dart';

class ProgrammingLanguage {
  final String name;
  final String displayName;
  final Mode mode;
  final List<String> extensions;

  const ProgrammingLanguage({
    required this.name,
    required this.displayName,
    required this.mode,
    required this.extensions,
  });
}

class PlanguageProvider extends ChangeNotifier {
  static final List<ProgrammingLanguage> _availableLanguages = [
    ProgrammingLanguage(
      name: 'dart',
      displayName: 'Dart',
      mode: langDart,
      extensions: ['.dart'],
    ),
    ProgrammingLanguage(
      name: 'python',
      displayName: 'Python',
      mode: langPython,
      extensions: ['.py', '.pyw'],
    ),
    ProgrammingLanguage(
      name: 'javascript',
      displayName: 'JavaScript',
      mode: langJavascript,
      extensions: ['.js', '.mjs', '.cjs'],
    ),
    ProgrammingLanguage(
      name: 'typescript',
      displayName: 'TypeScript',
      mode: langTypescript,
      extensions: ['.ts', '.tsx'],
    ),
    ProgrammingLanguage(
      name: 'java',
      displayName: 'Java',
      mode: langJava,
      extensions: ['.java'],
    ),
    ProgrammingLanguage(
      name: 'cpp',
      displayName: 'C++',
      mode: langCpp,
      extensions: ['.cpp', '.cc', '.cxx', '.hpp', '.h'],
    ),
    ProgrammingLanguage(
      name: 'c',
      displayName: 'C',
      mode: langC,
      extensions: ['.c', '.h'],
    ),
    ProgrammingLanguage(
      name: 'go',
      displayName: 'Go',
      mode: langGo,
      extensions: ['.go'],
    ),
    ProgrammingLanguage(
      name: 'rust',
      displayName: 'Rust',
      mode: langRust,
      extensions: ['.rs'],
    ),
    ProgrammingLanguage(
      name: 'ruby',
      displayName: 'Ruby',
      mode: langRuby,
      extensions: ['.rb'],
    ),
    ProgrammingLanguage(
      name: 'php',
      displayName: 'PHP',
      mode: langPhp,
      extensions: ['.php'],
    ),
    ProgrammingLanguage(
      name: 'csharp',
      displayName: 'C#',
      mode: langCsharp,
      extensions: ['.cs'],
    ),
    ProgrammingLanguage(
      name: 'swift',
      displayName: 'Swift',
      mode: langSwift,
      extensions: ['.swift'],
    ),
    ProgrammingLanguage(
      name: 'kotlin',
      displayName: 'Kotlin',
      mode: langKotlin,
      extensions: ['.kt', '.kts'],
    ),
    ProgrammingLanguage(
      name: 'json',
      displayName: 'JSON',
      mode: langJson,
      extensions: ['.json'],
    ),
    ProgrammingLanguage(
      name: 'xml',
      displayName: 'XML',
      mode: langXml,
      extensions: ['.xml'],
    ),
    ProgrammingLanguage(
      name: 'yaml',
      displayName: 'YAML',
      mode: langYaml,
      extensions: ['.yaml', '.yml'],
    ),
    ProgrammingLanguage(
      name: 'markdown',
      displayName: 'Markdown',
      mode: langMarkdown,
      extensions: ['.md', '.markdown'],
    ),
    ProgrammingLanguage(
      name: 'sql',
      displayName: 'SQL',
      mode: langSql,
      extensions: ['.sql'],
    ),
    ProgrammingLanguage(
      name: 'bash',
      displayName: 'Bash',
      mode: langBash,
      extensions: ['.sh', '.bash'],
    ),
  ];

  ProgrammingLanguage _currentLanguage =
      _availableLanguages[0]; // Dart by default

  ProgrammingLanguage get currentLanguage => _currentLanguage;
  List<ProgrammingLanguage> get availableLanguages => _availableLanguages;

  void setLanguage(ProgrammingLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  void setLanguageByName(String name) {
    final language = _availableLanguages.firstWhere(
      (lang) => lang.name == name,
      orElse: () => _availableLanguages[0],
    );
    setLanguage(language);
  }

  void setLanguageByExtension(String extension) {
    final language = _availableLanguages.firstWhere(
      (lang) => lang.extensions.contains(extension.toLowerCase()),
      orElse: () => _availableLanguages[0],
    );
    setLanguage(language);
  }

  /// Dosya uzantısına göre dili ayarlamaya çalışır.
  /// Eğer dil destekleniyorsa true, desteklenmiyorsa false döner.
  bool trySetLanguageByFilePath(String filePath) {
    if (filePath.isEmpty) return false;

    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return false;

    final extension = filePath.substring(dotIndex).toLowerCase();

    final language = _availableLanguages
        .where((lang) => lang.extensions.contains(extension))
        .firstOrNull;

    if (language != null) {
      setLanguage(language);
      return true;
    }
    return false;
  }

  /// Dosya uzantısından dil adını döndürür (desteklenmiyorsa null)
  String? getLanguageNameByFilePath(String filePath) {
    if (filePath.isEmpty) return null;

    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return null;

    final extension = filePath.substring(dotIndex).toLowerCase();

    return _availableLanguages
        .where((lang) => lang.extensions.contains(extension))
        .firstOrNull
        ?.displayName;
  }

  ProgrammingLanguage? detectLanguageFromFilePath(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;

    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return null;

    final extension = filePath.substring(dotIndex);
    return _availableLanguages.firstWhere(
      (lang) => lang.extensions.contains(extension.toLowerCase()),
      orElse: () => _availableLanguages[0],
    );
  }
}
