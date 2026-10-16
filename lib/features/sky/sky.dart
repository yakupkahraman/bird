import 'dart:ui' show Rect;

/// Where Sky's camera looks: canvas zoom and the canvas point at the top left.
typedef SkyView = ({double scale, double x, double y});

/// Sky's canvas for one folder: where each node sits, and what is in view.
class SkyLayout {
  SkyLayout({Map<String, Rect>? nodes, this.view}) : nodes = nodes ?? {};

  factory SkyLayout.fromJson(Map<String, Object?> json) {
    final nodes = json['nodes'];
    final view = json['view'];
    return SkyLayout(
      nodes: {
        if (nodes is Map)
          for (final MapEntry(:key, :value) in nodes.entries)
            if (key is String && value is List && value.length == 4)
              key: Rect.fromLTWH(
                (value[0] as num).toDouble(),
                (value[1] as num).toDouble(),
                (value[2] as num).toDouble(),
                (value[3] as num).toDouble(),
              ),
      },
      view: view is List && view.length == 3
          ? (
              scale: (view[0] as num).toDouble(),
              x: (view[1] as num).toDouble(),
              y: (view[2] as num).toDouble(),
            )
          : null,
    );
  }

  /// By tab path. A closed tab keeps its entry, so reopening it lands where it
  /// was left.
  final Map<String, Rect> nodes;

  SkyView? view;

  Map<String, Object?> toJson() => {
    'nodes': {
      for (final MapEntry(:key, value: r) in nodes.entries)
        key: [r.left, r.top, r.width, r.height],
    },
    if (view case final v?) 'view': [v.scale, v.x, v.y],
  };
}
