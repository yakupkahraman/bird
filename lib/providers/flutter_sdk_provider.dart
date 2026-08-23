import 'dart:async';

import 'package:bird/models/flutter_sdk.dart';
import 'package:bird/providers/settings_provider.dart';
import 'package:bird/services/flutter_sdk_service.dart';
import 'package:flutter/foundation.dart';

/// Which Flutter SDK Bird uses, and what the SDK service is doing right now.
///
/// It owns no processes and no sockets: [FlutterSdkService] does the work and
/// reports back, and this turns those reports into state a widget can watch.
class FlutterSdkProvider extends ChangeNotifier {
  /// [bundledRoot] is only passed by tests, so they never touch the real one.
  FlutterSdkProvider({String? bundledRoot}) {
    _service = FlutterSdkService(
      bundledRoot: bundledRoot,
      onPhase: _setPhase,
      onLog: _append,
      onProgress: _setProgress,
    );
    detectSdk();
  }

  late final FlutterSdkService _service;

  final List<FlutterSdkInfo> _found = [];
  FlutterSdkInfo? _sdkInfo;
  FlutterSdkLocation? _preferred;
  bool _isDetecting = false;
  bool _rescanQueued = false;
  bool _isBusy = false;
  SdkInstallPhase _phase = SdkInstallPhase.idle;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  double _bytesPerSecond = 0;
  String _statusMessage = '';
  String? _lastError;
  final List<String> _log = [];
  String _lastDoctorOutput = '';
  SettingsProvider? _settings;
  bool _isDisposed = false;

  /// Repainting on every downloaded chunk would spend the whole download in
  /// layout, so notifications during one are rate limited.
  final Stopwatch _sinceNotify = Stopwatch()..start();

  /// Most recent lines are last; the console view tails this.
  static const int _logLimit = 500;

  FlutterSdkInfo? get sdkInfo => _sdkInfo;
  bool get isDetecting => _isDetecting;
  bool get isBusy => _isBusy;
  SdkInstallPhase get phase => _phase;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  double get downloadProgress =>
      _totalBytes <= 0 ? 0.0 : _receivedBytes / _totalBytes;
  double get bytesPerSecond => _bytesPerSecond;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;
  List<String> get installLog => List.unmodifiable(_log);
  String get lastDoctorOutput => _lastDoctorOutput;

  /// The bundled versions, newest first.
  List<FlutterSdkInfo> get bundledSdks =>
      _found.where((sdk) => sdk.isBundled).toList();

  /// The SDK found at [location] — for bundled, the newest of them.
  FlutterSdkInfo? sdkAt(FlutterSdkLocation location) => _at(location);

  /// The source the user picked, or null while Bird is choosing for them.
  FlutterSdkLocation? get preferredLocation => _preferred;

  /// The version a project (or the user) asked for by name.
  String? get pinnedVersion => _settings?.flutterVersion;

  /// A pinned version that is not installed: the project wants an SDK Bird
  /// does not have, which the settings page offers to fetch.
  String? get missingPinnedVersion {
    final pinned = pinnedVersion;
    if (pinned == null) return null;
    return bundledSdks.any((sdk) => sdk.flutterVersion == pinned)
        ? null
        : pinned;
  }

  /// How long the running download still needs, or null before a rate is known.
  Duration? get eta {
    if (_bytesPerSecond <= 0 || _totalBytes <= 0) return null;
    final remaining = (_totalBytes - _receivedBytes) / _bytesPerSecond;
    return Duration(seconds: remaining.round());
  }

  /// Called from proxy provider to sync configured SDK preferences.
  void attachSettings(SettingsProvider settings) {
    if (identical(_settings, settings)) return;
    _settings = settings;
    detectSdk(customPath: settings.flutterSdkPath);
  }

  /// Looks for an SDK in every source, then activates the preferred one.
  ///
  /// All of them are kept, not just the winner: the settings view lists them
  /// side by side so the user can switch without Bird guessing.
  Future<void> detectSdk({String? customPath}) async {
    // A scan asked for while one is running is not dropped: settings attach a
    // moment after the constructor already started one, and losing that pass
    // would ignore the user's pinned source until the next rescan.
    if (_isDetecting) {
      _rescanQueued = true;
      return;
    }
    _isDetecting = true;
    _notify();

    try {
      _found.clear();
      await _service.adoptLegacyInstall();
      for (final version in _service.installedVersions()) {
        await _record(
          FlutterSdkLocation.bundled,
          _service.versionPath(version),
        );
      }
      await _record(
        FlutterSdkLocation.custom,
        customPath ?? _settings?.flutterSdkPath,
      );
      await _record(FlutterSdkLocation.system, await _service.findSystemSdk());
      _activate();
    } finally {
      _isDetecting = false;
      _notify();
      if (_rescanQueued) {
        _rescanQueued = false;
        await detectSdk();
      }
    }
  }

  Future<void> _record(FlutterSdkLocation location, String? sdkPath) async {
    if (sdkPath == null || sdkPath.isEmpty) return;
    final info = await _service.inspect(sdkPath, location);
    if (info != null) _found.add(info);
  }

  /// A version named by name wins: it is what a project pins itself to. After
  /// that the user's chosen source, and failing everything, whatever was found.
  void _activate() {
    _preferred = FlutterSdkLocation.values
        .where((l) => l.name == _settings?.flutterPreferredLocation)
        .firstOrNull;

    final pinned = pinnedVersion;
    _sdkInfo =
        (pinned == null
            ? null
            : bundledSdks.firstWhereOrNull(
                (sdk) => sdk.flutterVersion == pinned,
              )) ??
        _at(_preferred) ??
        _at(FlutterSdkLocation.bundled) ??
        _at(FlutterSdkLocation.custom) ??
        _at(FlutterSdkLocation.system);
  }

  FlutterSdkInfo? _at(FlutterSdkLocation? location) => location == null
      ? null
      : _found.firstWhereOrNull((sdk) => sdk.location == location);

  /// Pins the SDK Bird uses, so a system install no longer loses to a bundled
  /// one just because of the search order. Persisted across restarts.
  Future<void> selectLocation(FlutterSdkLocation location) async {
    final info = _at(location);
    if (info == null) return;
    _preferred = location;
    _sdkInfo = info;
    _lastError = null;
    _notify();
    await _settings?.set('flutter.preferredLocation', location.name);
    // Choosing a source by hand drops the user's version pin; a project's own
    // pin lives in its workspace file and is left alone.
    if (location != FlutterSdkLocation.bundled) {
      await _settings?.set('flutter.version', null);
    }
  }

  /// Switches to an installed bundled version. Instant: nothing is downloaded.
  Future<void> selectVersion(String version) async {
    final info = bundledSdks.firstWhereOrNull(
      (sdk) => sdk.flutterVersion == version,
    );
    if (info == null) return;
    _preferred = FlutterSdkLocation.bundled;
    _sdkInfo = info;
    _lastError = null;
    _notify();
    await _settings?.set('flutter.preferredLocation', 'bundled');
    await _settings?.set('flutter.version', version);
  }

  /// Points the custom slot at [sdkPath] and switches to it.
  Future<bool> setCustomPath(String sdkPath) async {
    final info = await _service.inspect(sdkPath, FlutterSdkLocation.custom);
    if (info == null) {
      _lastError = 'No Flutter SDK under $sdkPath';
      _notify();
      return false;
    }
    await _settings?.set('flutter.sdkPath', sdkPath);
    _found.removeWhere((sdk) => sdk.location == FlutterSdkLocation.custom);
    _found.add(info);
    await selectLocation(FlutterSdkLocation.custom);
    return true;
  }

  /// Every version installable on this machine, newest first.
  Future<List<({String version, String channel})>> availableReleases() async {
    try {
      return await _service.fetchReleases();
    } catch (e) {
      _lastError = _readable(e);
      _notify();
      return const [];
    }
  }

  /// Installs [version], or the tip of [channel] when no version is named.
  Future<bool> downloadAndInstallBundledSdk({
    String channel = 'stable',
    String? version,
  }) => _work(
    SdkInstallPhase.resolving,
    'Fetching release information...',
    () async {
      _receivedBytes = 0;
      _totalBytes = 0;
      _bytesPerSecond = 0;
      final installed = await _service.install(
        channel: channel,
        version: version,
      );
      _setPhase(SdkInstallPhase.done, 'Flutter $installed installed.');
      await detectSdk();
      await selectVersion(installed);
    },
    'Installation failed.',
  );

  /// Switches the Flutter channel on the active SDK.
  Future<bool> switchChannel(String channel) {
    final info = _sdkInfo;
    if (info == null) return Future.value(false);
    return _work(SdkInstallPhase.running, 'Switching to $channel...', () async {
      await _service.switchChannel(info, channel);
      _setPhase(SdkInstallPhase.done, 'Switched to $channel.');
      await detectSdk();
    }, 'Failed to switch channel.');
  }

  /// Runs `flutter upgrade` on the active SDK.
  Future<bool> upgradeSdk() {
    final info = _sdkInfo;
    if (info == null) return Future.value(false);
    return _work(SdkInstallPhase.running, 'Upgrading Flutter SDK...', () async {
      await _service.upgrade(info);
      _setPhase(SdkInstallPhase.done, 'Flutter SDK upgraded.');
      await detectSdk();
    }, 'Upgrade failed.');
  }

  /// Runs `flutter doctor -v` and keeps the report.
  Future<String> runDoctor() async {
    final info = _sdkInfo;
    if (info == null) return 'No Flutter SDK available.';
    await _work(SdkInstallPhase.running, 'Running flutter doctor...', () async {
      _lastDoctorOutput = await _service.doctor(info);
      _setPhase(SdkInstallPhase.idle, '');
    }, 'Failed to run flutter doctor.');
    return _lastDoctorOutput;
  }

  /// Deletes one installed version, leaving the others alone.
  Future<void> deleteBundledSdk(String version) async {
    if (_isBusy) return;
    try {
      await _service.deleteVersion(version);
      if (_settings?.flutterVersion == version) {
        await _settings?.set('flutter.version', null);
      }
      if (_service.installedVersions().isEmpty &&
          _preferred == FlutterSdkLocation.bundled) {
        await _settings?.set('flutter.preferredLocation', null);
      }
      await detectSdk();
    } catch (e) {
      _lastError = _readable(e);
      debugPrint('Failed to delete bundled SDK: $e');
      _notify();
    }
  }

  /// Stops whatever the service is doing.
  void cancelInstall() {
    if (!_isBusy) return;
    _service.cancel();
    _append('Cancelled by user.');
    _notify();
  }

  /// Drops the doctor report, for when the user is done reading it.
  void clearDoctorOutput() {
    if (_lastDoctorOutput.isEmpty) return;
    _lastDoctorOutput = '';
    _notify();
  }

  /// Runs one long operation, holding the busy state and turning whatever it
  /// throws into something the settings page can show.
  Future<bool> _work(
    SdkInstallPhase phase,
    String message,
    Future<void> Function() body,
    String failure,
  ) async {
    if (_isBusy) return false;
    _isBusy = true;
    _lastError = null;
    _log.clear();
    _service.begin();
    _setPhase(phase, message);

    try {
      await body();
      return true;
    } on SdkCancelled {
      _setPhase(SdkInstallPhase.idle, 'Cancelled.');
      return false;
    } catch (e) {
      _lastError = _readable(e);
      _append('Failed: $e');
      _setPhase(SdkInstallPhase.failed, failure);
      debugPrint('$failure $e');
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  /// The banner shows this to the user, and 'Exception: ' is noise to them.
  static String _readable(Object error) =>
      '$error'.replaceFirst(RegExp(r'^Exception: '), '');

  void _setPhase(SdkInstallPhase phase, String message) {
    _phase = phase;
    _statusMessage = message;
    if (message.isNotEmpty) _append(message);
    _notify();
  }

  void _setProgress(int received, int total, double bytesPerSecond) {
    _receivedBytes = received;
    _totalBytes = total;
    _bytesPerSecond = bytesPerSecond;
    _statusMessage =
        '${formatBytes(received)} of ${formatBytes(total)}'
        ' • ${formatBytes(bytesPerSecond.round())}/s';
    _notifyThrottled();
  }

  void _append(String line) {
    if (line.trim().isEmpty) return;
    _log.add(line);
    if (_log.length > _logLimit) {
      _log.removeRange(0, _log.length - _logLimit);
    }
    _notifyThrottled();
  }

  void _notify() {
    _sinceNotify.reset();
    if (!_isDisposed) notifyListeners();
  }

  void _notifyThrottled() {
    if (_sinceNotify.elapsedMilliseconds < 80) return;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _service.dispose();
    super.dispose();
  }
}
