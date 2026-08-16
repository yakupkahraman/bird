import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class _FileIconData {
  final IconData icon;
  final Color color;

  const _FileIconData(this.icon, this.color);
}

/// Custom Nerd Font-based File Icon component.
///
/// Automatically determines the appropriate icon and color based on
/// the filename, extension, or full path.
class FileIcon extends StatelessWidget {
  final String path;
  final double size;
  final Color? color;
  final bool isMonochrome;

  const FileIcon(
    this.path, {
    super.key,
    this.size = 16,
    this.color,
    this.isMonochrome = false,
  });

  static const String _fontFamily = 'NerdFont';

  static const Map<String, _FileIconData> _exactFiles = {
    'pubspec.yaml': _FileIconData(
      IconData(0xe798, fontFamily: _fontFamily),
      Color(0xFF00B4AB),
    ),
    'pubspec.lock': _FileIconData(
      IconData(0xea75, fontFamily: _fontFamily),
      Color(0xFF00B4AB),
    ),
    '.gitignore': _FileIconData(
      IconData(0xe702, fontFamily: _fontFamily),
      Color(0xFFF05032),
    ),
    '.gitattributes': _FileIconData(
      IconData(0xe702, fontFamily: _fontFamily),
      Color(0xFFF05032),
    ),
    '.gitmodules': _FileIconData(
      IconData(0xe702, fontFamily: _fontFamily),
      Color(0xFFF05032),
    ),
    'dockerfile': _FileIconData(
      IconData(0xe7b0, fontFamily: _fontFamily),
      Color(0xFF2496ED),
    ),
    'docker-compose.yml': _FileIconData(
      IconData(0xe7b0, fontFamily: _fontFamily),
      Color(0xFF2496ED),
    ),
    'docker-compose.yaml': _FileIconData(
      IconData(0xe7b0, fontFamily: _fontFamily),
      Color(0xFF2496ED),
    ),
    'readme.md': _FileIconData(
      IconData(0xf0f5b, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    'readme': _FileIconData(
      IconData(0xf0f5b, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    'license': _FileIconData(
      IconData(0xf0fc3, fontFamily: _fontFamily),
      Color(0xFFD4E157),
    ),
    'license.md': _FileIconData(
      IconData(0xf0fc3, fontFamily: _fontFamily),
      Color(0xFFD4E157),
    ),
    'license.txt': _FileIconData(
      IconData(0xf0fc3, fontFamily: _fontFamily),
      Color(0xFFD4E157),
    ),
    'makefile': _FileIconData(
      IconData(0xe673, fontFamily: _fontFamily),
      Color(0xFF817970),
    ),
    'cmakelists.txt': _FileIconData(
      IconData(0xe673, fontFamily: _fontFamily),
      Color(0xFF064F8C),
    ),
  };

  static const Map<String, _FileIconData> _extensions = {
    // Dart & Flutter
    '.dart': _FileIconData(
      IconData(0xe798, fontFamily: _fontFamily),
      Color(0xFF0175C2),
    ),

    // C / C++
    '.c': _FileIconData(
      IconData(0xe61e, fontFamily: _fontFamily),
      Color(0xFF599E5E),
    ),
    '.h': _FileIconData(
      IconData(0xe61e, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.cpp': _FileIconData(
      IconData(0xe61d, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    '.cc': _FileIconData(
      IconData(0xe61d, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    '.cxx': _FileIconData(
      IconData(0xe61d, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    '.hpp': _FileIconData(
      IconData(0xe61d, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.hxx': _FileIconData(
      IconData(0xe61d, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),

    // Web & JavaScript / TypeScript
    '.js': _FileIconData(
      IconData(0xe74e, fontFamily: _fontFamily),
      Color(0xFFF1E05A),
    ),
    '.mjs': _FileIconData(
      IconData(0xe74e, fontFamily: _fontFamily),
      Color(0xFFF1E05A),
    ),
    '.cjs': _FileIconData(
      IconData(0xe74e, fontFamily: _fontFamily),
      Color(0xFFF1E05A),
    ),
    '.ts': _FileIconData(
      IconData(0xe628, fontFamily: _fontFamily),
      Color(0xFF3178C6),
    ),
    '.jsx': _FileIconData(
      IconData(0xe7ba, fontFamily: _fontFamily),
      Color(0xFF61DAFB),
    ),
    '.tsx': _FileIconData(
      IconData(0xe7ba, fontFamily: _fontFamily),
      Color(0xFF61DAFB),
    ),
    '.html': _FileIconData(
      IconData(0xe736, fontFamily: _fontFamily),
      Color(0xFFE34C26),
    ),
    '.htm': _FileIconData(
      IconData(0xe736, fontFamily: _fontFamily),
      Color(0xFFE34C26),
    ),
    '.css': _FileIconData(
      IconData(0xe749, fontFamily: _fontFamily),
      Color(0xFF563D7C),
    ),
    '.scss': _FileIconData(
      IconData(0xe74b, fontFamily: _fontFamily),
      Color(0xFFC6538C),
    ),
    '.sass': _FileIconData(
      IconData(0xe74b, fontFamily: _fontFamily),
      Color(0xFFC6538C),
    ),
    '.less': _FileIconData(
      IconData(0xe758, fontFamily: _fontFamily),
      Color(0xFF1D365D),
    ),

    // Data & Config
    '.json': _FileIconData(
      IconData(0xf0626, fontFamily: _fontFamily),
      Color(0xFFCBCB41),
    ),
    '.yaml': _FileIconData(
      IconData(0xe8eb, fontFamily: _fontFamily),
      Color(0xFFCB171E),
    ),
    '.yml': _FileIconData(
      IconData(0xe8eb, fontFamily: _fontFamily),
      Color(0xFFCB171E),
    ),
    '.toml': _FileIconData(
      IconData(0xe6b2, fontFamily: _fontFamily),
      Color(0xFF9C4221),
    ),
    '.xml': _FileIconData(
      IconData(0xe619, fontFamily: _fontFamily),
      Color(0xFF005F9E),
    ),
    '.csv': _FileIconData(
      IconData(0xeae0, fontFamily: _fontFamily),
      Color(0xFF237346),
    ),
    '.env': _FileIconData(
      IconData(0xe615, fontFamily: _fontFamily),
      Color(0xFFFAF743),
    ),
    '.lock': _FileIconData(
      IconData(0xf023, fontFamily: _fontFamily),
      Color(0xFF78909C),
    ),

    // Docs & Markdown
    '.md': _FileIconData(
      IconData(0xf0f5b, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    '.markdown': _FileIconData(
      IconData(0xf0f5b, fontFamily: _fontFamily),
      Color(0xFF519ABA),
    ),
    '.txt': _FileIconData(
      IconData(0xeae0, fontFamily: _fontFamily),
      Color(0xFF888888),
    ),
    '.pdf': _FileIconData(
      IconData(0xf1c1, fontFamily: _fontFamily),
      Color(0xFFE53935),
    ),

    // Other Programming Languages
    '.py': _FileIconData(
      IconData(0xe73c, fontFamily: _fontFamily),
      Color(0xFF3572A5),
    ),
    '.pyw': _FileIconData(
      IconData(0xe73c, fontFamily: _fontFamily),
      Color(0xFF3572A5),
    ),
    '.rs': _FileIconData(
      IconData(0xe7a8, fontFamily: _fontFamily),
      Color(0xFFDEA584),
    ),
    '.go': _FileIconData(
      IconData(0xe627, fontFamily: _fontFamily),
      Color(0xFF00ADD8),
    ),
    '.java': _FileIconData(
      IconData(0xe738, fontFamily: _fontFamily),
      Color(0xFFB07219),
    ),
    '.class': _FileIconData(
      IconData(0xe738, fontFamily: _fontFamily),
      Color(0xFFB07219),
    ),
    '.jar': _FileIconData(
      IconData(0xe738, fontFamily: _fontFamily),
      Color(0xFFB07219),
    ),
    '.kt': _FileIconData(
      IconData(0xe634, fontFamily: _fontFamily),
      Color(0xFFF18E33),
    ),
    '.kts': _FileIconData(
      IconData(0xe634, fontFamily: _fontFamily),
      Color(0xFFF18E33),
    ),
    '.swift': _FileIconData(
      IconData(0xe755, fontFamily: _fontFamily),
      Color(0xFFFFAC45),
    ),
    '.php': _FileIconData(
      IconData(0xe73d, fontFamily: _fontFamily),
      Color(0xFF4F5D95),
    ),
    '.rb': _FileIconData(
      IconData(0xe739, fontFamily: _fontFamily),
      Color(0xFF701516),
    ),
    '.lua': _FileIconData(
      IconData(0xe620, fontFamily: _fontFamily),
      Color(0xFF000080),
    ),
    '.sh': _FileIconData(
      IconData(0xe795, fontFamily: _fontFamily),
      Color(0xFF4EAA25),
    ),
    '.bash': _FileIconData(
      IconData(0xe795, fontFamily: _fontFamily),
      Color(0xFF4EAA25),
    ),
    '.zsh': _FileIconData(
      IconData(0xe795, fontFamily: _fontFamily),
      Color(0xFF4EAA25),
    ),
    '.sql': _FileIconData(
      IconData(0xe706, fontFamily: _fontFamily),
      Color(0xFFE38C00),
    ),

    // Images & Media
    '.png': _FileIconData(
      IconData(0xf0e2d, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.jpg': _FileIconData(
      IconData(0xf0225, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.jpeg': _FileIconData(
      IconData(0xf0225, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.gif': _FileIconData(
      IconData(0xf0d78, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.svg': _FileIconData(
      IconData(0xe698, fontFamily: _fontFamily),
      Color(0xFFFFB13B),
    ),
    '.webp': _FileIconData(
      IconData(0xea7e, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),
    '.ico': _FileIconData(
      IconData(0xea7e, fontFamily: _fontFamily),
      Color(0xFFA074C4),
    ),

    // Archives
    '.zip': _FileIconData(
      IconData(0xf1c6, fontFamily: _fontFamily),
      Color(0xFFFFB74D),
    ),
    '.tar': _FileIconData(
      IconData(0xf1c6, fontFamily: _fontFamily),
      Color(0xFFFFB74D),
    ),
    '.gz': _FileIconData(
      IconData(0xf1c6, fontFamily: _fontFamily),
      Color(0xFFFFB74D),
    ),
    '.7z': _FileIconData(
      IconData(0xf1c6, fontFamily: _fontFamily),
      Color(0xFFFFB74D),
    ),
    '.rar': _FileIconData(
      IconData(0xf1c6, fontFamily: _fontFamily),
      Color(0xFFFFB74D),
    ),
  };

  static const _FileIconData _defaultIcon = _FileIconData(
    IconData(0xf09a8, fontFamily: _fontFamily),
    Color(0xFF90A4AE),
  );

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(path).toLowerCase();
    final ext = p.extension(path).toLowerCase();

    _FileIconData iconData =
        _exactFiles[fileName] ?? _extensions[ext] ?? _defaultIcon;

    Color displayColor;
    if (color != null) {
      displayColor = color!;
    } else if (isMonochrome) {
      displayColor = Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.7);
    } else {
      displayColor = iconData.color;
    }

    return Icon(iconData.icon, size: size, color: displayColor);
  }
}
