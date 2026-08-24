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

/// The languages `re_highlight` is registered for.
///
/// Not a provider: there is no state here to change and nothing to listen to.
/// Which language a file uses belongs to that file, on its `EditorDocument`.
/// Adding one is an import above plus an entry in this list.
abstract final class Languages {
  static final List<ProgrammingLanguage> _all = [
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

  /// The language for a file, or null when its extension is not one Bird
  /// knows. Null means plain text, not "highlight it as the last file" — a
  /// single current language used to live in a provider, and that is exactly
  /// how a .txt file ended up coloured as Dart.
  static ProgrammingLanguage? forPath(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return null;

    final extension = filePath.substring(dotIndex).toLowerCase();
    return _all
        .where((language) => language.extensions.contains(extension))
        .firstOrNull;
  }
}
