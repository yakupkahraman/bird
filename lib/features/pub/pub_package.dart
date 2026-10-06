/// A document pub.dev shows from inside a package's archive.
enum PubDoc { readme, changelog, example }

/// A package as pub.dev describes it, from its package and score endpoints.
class PubPackage {
  const PubPackage({
    required this.name,
    required this.version,
    required this.description,
    this.publisher,
    this.license,
    this.repository,
    this.homepage,
    this.platforms = const [],
    this.likes = 0,
    this.points = 0,
    this.maxPoints = 0,
    this.downloads = 0,
    this.isDiscontinued = false,
    this.versions = const [],
  });

  /// [package] is `/api/packages/<name>`, [score] is `.../score`. pub.dev only
  /// reports publisher, platforms and license as tags on the score.
  factory PubPackage.fromJson(
    Map<String, dynamic> package,
    Map<String, dynamic> score,
  ) {
    final latest = package['latest'] as Map<String, dynamic>;
    final pubspec = latest['pubspec'] as Map<String, dynamic>;
    final tags = [...?score['tags'] as List?].cast<String>();
    Iterable<String> tagged(String prefix) => tags
        .where((tag) => tag.startsWith(prefix))
        .map((tag) => tag.substring(prefix.length));

    return PubPackage(
      name: package['name'] as String,
      version: latest['version'] as String,
      description: (pubspec['description'] as String? ?? '').trim(),
      publisher: tagged('publisher:').firstOrNull,
      // fsf-libre and osi-approved are classifications, not a licence.
      license: tagged(
        'license:',
      ).where((l) => l != 'fsf-libre' && l != 'osi-approved').firstOrNull,
      repository: pubspec['repository'] as String?,
      homepage: pubspec['homepage'] as String?,
      platforms: tagged('platform:').toList(),
      likes: score['likeCount'] as int? ?? 0,
      points: score['grantedPoints'] as int? ?? 0,
      maxPoints: score['maxPoints'] as int? ?? 0,
      downloads: score['downloadCount30Days'] as int? ?? 0,
      isDiscontinued: package['isDiscontinued'] as bool? ?? false,
      // pub.dev lists them oldest first.
      versions: [
        for (final v in (package['versions'] as List? ?? const []).reversed)
          (
            version: v['version'] as String,
            published: DateTime.tryParse(v['published'] as String? ?? ''),
          ),
      ],
    );
  }

  final String name;
  final String version;
  final String description;
  final String? publisher;
  final String? license;
  final String? repository;
  final String? homepage;
  final List<String> platforms;
  final int likes;
  final int points;
  final int maxPoints;

  /// Over the last 30 days.
  final int downloads;
  final bool isDiscontinued;

  /// Every published version, newest first.
  final List<({String version, DateTime? published})> versions;

  Uri get pubUri => Uri.https('pub.dev', '/packages/$name');
}

/// A dependency of the open project, as `pub outdated --json` reports it.
class Dependency {
  const Dependency({
    required this.name,
    required this.isDev,
    this.current,
    this.latest,
    this.isDiscontinued = false,
  });

  final String name;
  final bool isDev;

  /// The resolved version; null until `pub get` has run.
  final String? current;

  /// The newest version on pub.dev, whether or not the constraint allows it.
  final String? latest;
  final bool isDiscontinued;

  bool get canUpgrade => current != null && latest != null && current != latest;

  /// The project's own dependencies; the report also lists transitive ones,
  /// which the project does not declare and so cannot remove or upgrade.
  static List<Dependency> parseOutdated(Map<String, dynamic> json) => [
    for (final entry in (json['packages'] as List).cast<Map<String, dynamic>>())
      if (entry['kind'] case 'direct' || 'dev')
        Dependency(
          name: entry['package'] as String,
          isDev: entry['kind'] == 'dev',
          current: (entry['current'] as Map?)?['version'] as String?,
          latest: (entry['latest'] as Map?)?['version'] as String?,
          isDiscontinued: entry['isDiscontinued'] as bool? ?? false,
        ),
  ];
}
