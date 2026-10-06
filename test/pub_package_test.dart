import 'package:bird/features/pub/pub_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package and score responses combine into one package', () {
    final package = PubPackage.fromJson(
      {
        'name': 'http',
        'latest': {
          'version': '1.6.0',
          'pubspec': {
            'description': ' A composable HTTP API. ',
            'repository': 'https://github.com/dart-lang/http',
          },
        },
      },
      {
        'grantedPoints': 160,
        'maxPoints': 160,
        'likeCount': 8475,
        'downloadCount30Days': 12497778,
        'tags': [
          'publisher:dart.dev',
          'platform:android',
          'platform:macos',
          'license:bsd-3-clause',
          'license:fsf-libre',
          'license:osi-approved',
        ],
      },
    );

    expect(package.version, '1.6.0');
    expect(package.description, 'A composable HTTP API.');
    expect(package.publisher, 'dart.dev');
    // The classification tags are not the licence.
    expect(package.license, 'bsd-3-clause');
    expect(package.platforms, ['android', 'macos']);
    expect(package.likes, 8475);
    expect(package.pubUri.toString(), 'https://pub.dev/packages/http');
  });

  test('only the project\'s own dependencies come out of pub outdated', () {
    final dependencies = Dependency.parseOutdated({
      'packages': [
        {
          'package': 'file_picker',
          'kind': 'direct',
          'current': {'version': '10.3.10'},
          'latest': {'version': '13.1.0'},
        },
        {
          'package': 'flutter_lints',
          'kind': 'dev',
          'current': {'version': '6.0.0'},
          'latest': {'version': '6.0.0'},
        },
        {'package': 'meta', 'kind': 'transitive', 'current': null},
      ],
    });

    expect(dependencies.map((d) => d.name), ['file_picker', 'flutter_lints']);
    expect(dependencies.first.canUpgrade, isTrue);
    expect(dependencies.last.isDev, isTrue);
    expect(dependencies.last.canUpgrade, isFalse);
  });
}
