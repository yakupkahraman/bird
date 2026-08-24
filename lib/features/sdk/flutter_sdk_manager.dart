import 'package:bird/features/sdk/flutter_sdk.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/sdk/log_console.dart';
import 'package:bird/core/ui/mini_button.dart';
import 'package:bird/core/ui/my_button.dart';
import 'package:bird/core/ui/my_menu_item.dart';
import 'package:bird/core/ui/my_tile.dart';
import 'package:bird/core/ui/nf_icons.dart';
import 'package:bird/core/ui/section_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Flutter SDK page of the settings dialog.
///
/// Every source Bird knows about is listed at once — the SDK it installed
/// itself, one the user pointed it at, and whatever is on the machine already —
/// and the user picks which one is in charge. Installing is a two gigabyte
/// download, so it reports its bytes, its rate and its subprocess output rather
/// than a spinner.
class FlutterSdkManager extends StatefulWidget {
  const FlutterSdkManager({super.key});

  /// The sources shown as a single row each. Bundled SDKs are not here: there
  /// is a row per installed version instead.
  static const sources = [FlutterSdkLocation.system, FlutterSdkLocation.custom];

  @override
  State<FlutterSdkManager> createState() => _FlutterSdkManagerState();
}

class _FlutterSdkManagerState extends State<FlutterSdkManager> {
  final ScrollController _scroll = ScrollController();
  bool _hadOutput = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Output appears at the top of the page; take the user there with it, rather
  /// than leaving them looking at the button they pressed further down.
  void _revealOutput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || _scroll.offset == 0) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final provider = context.watch<FlutterSdkProvider>();
    final active = provider.sdkInfo;

    final doctor = provider.lastDoctorOutput;
    final hasOutput =
        provider.isBusy || provider.lastError != null || doctor.isNotEmpty;
    if (hasOutput && !_hadOutput) _revealOutput();
    _hadOutput = hasOutput;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // One place for everything a command has to say — running or finished,
        // output or error. Anything else means hunting for the answer.
        if (provider.isBusy) ...[
          _progress(context, provider, primary),
          const SizedBox(height: 20),
        ],
        if (provider.lastError case final error?) _banner(error, primary),
        if (!provider.isBusy && doctor.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: SectionHeader('Flutter Doctor')),
              MiniButton(
                icon: NfIcons.close,
                tooltip: 'Dismiss output',
                onPressed: provider.clearDoctorOutput,
              ),
            ],
          ),
          LogConsole(lines: doctor.split('\n'), height: 220),
          const SizedBox(height: 20),
        ],

        Row(
          children: [
            Expanded(child: SectionHeader('SDK Source')),
            MiniButton(
              icon: NfIcons.refresh,
              tooltip: 'Scan again',
              onPressed: provider.isDetecting || provider.isBusy
                  ? null
                  : () => provider.detectSdk(),
            ),
          ],
        ),
        if (provider.isDetecting)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (provider.missingPinnedVersion case final wanted?)
            _missingPin(context, provider, wanted, primary),
          for (final sdk in provider.bundledSdks)
            _versionTile(context, provider, sdk, primary),
          _installTile(context, provider),
          for (final source in FlutterSdkManager.sources)
            _sourceTile(context, provider, source, primary),
        ],

        if (active != null) ...[
          const SizedBox(height: 20),
          SectionHeader('Active SDK'),
          _activeCard(active, primary),
          const SizedBox(height: 20),
          SectionHeader('Channel & Upgrades'),
          _channels(provider, active),
          const SizedBox(height: 12),
          SectionHeader('Actions & Diagnostics'),
          _actions(provider),
        ],
      ],
    );
  }

  /// One installed version. Switching between them costs nothing: they are all
  /// on disk already.
  Widget _versionTile(
    BuildContext context,
    FlutterSdkProvider provider,
    FlutterSdkInfo sdk,
    Color primary,
  ) {
    final isActive = provider.sdkInfo?.sdkPath == sdk.sdkPath;
    final isPinned = provider.pinnedVersion == sdk.flutterVersion;

    return MyTile(
      leading: _radio(isActive, primary),
      title: 'Flutter ${sdk.flutterVersion}${isPinned ? '  (pinned)' : ''}',
      subtitle:
          'Bundled • Dart ${sdk.dartVersion} • ${sdk.channel}\n${sdk.sdkPath}',
      trailing: MyButton(
        label: 'Delete',
        icon: NfIcons.trash,
        height: 28,
        fontSize: 11.5,
        variant: MyButtonVariant.outline,
        onPressed: provider.isBusy
            ? null
            : () async {
                if (await _confirmDeletion(context, sdk.flutterVersion)) {
                  await provider.deleteBundledSdk(sdk.flutterVersion);
                }
              },
      ),
      onTap: provider.isBusy
          ? null
          : () => provider.selectVersion(sdk.flutterVersion),
    );
  }

  /// Adds a version to the shelf. Every published release is on offer, not just
  /// the tip of a channel.
  Widget _installTile(BuildContext context, FlutterSdkProvider provider) {
    final hasAny = provider.bundledSdks.isNotEmpty;
    return MyTile(
      icon: NfIcons.flutter,
      title: hasAny
          ? 'Install another Flutter version'
          : 'Install a Flutter version',
      subtitle:
          'Downloaded from flutter.dev into Bird\'s own directory, next to any '
          'version already there.',
      trailing: MyButton(
        label: 'Choose version...',
        height: 28,
        fontSize: 11.5,
        variant: hasAny ? MyButtonVariant.outline : MyButtonVariant.primary,
        onPressed: provider.isBusy ? null : () => _chooseVersion(context),
      ),
      onTap: provider.isBusy ? null : () => _chooseVersion(context),
    );
  }

  /// A project asked for a version this machine does not have.
  Widget _missingPin(
    BuildContext context,
    FlutterSdkProvider provider,
    String wanted,
    Color primary,
  ) {
    return MyTile(
      icon: NfIcons.warning,
      title: 'This project asks for Flutter $wanted',
      subtitle: 'It is pinned in the project settings but is not installed.',
      backgroundColor: Colors.amber.withValues(alpha: 0.08),
      borderColor: Colors.amber.withValues(alpha: 0.3),
      trailing: MyButton(
        label: 'Install $wanted',
        height: 28,
        fontSize: 11.5,
        onPressed: provider.isBusy
            ? null
            : () => provider.downloadAndInstallBundledSdk(version: wanted),
      ),
    );
  }

  /// One selectable source. Tapping a row that has an SDK switches to it;
  /// tapping one that has none runs the thing that would give it one.
  Widget _sourceTile(
    BuildContext context,
    FlutterSdkProvider provider,
    FlutterSdkLocation source,
    Color primary,
  ) {
    final info = provider.sdkAt(source);
    final isActive = provider.sdkInfo?.location == source;
    final isPinned = provider.preferredLocation == source;

    final subtitle = info == null
        ? switch (source) {
            FlutterSdkLocation.system =>
              'No flutter found on PATH or in the usual install directories.',
            _ => 'No folder selected yet.',
          }
        : 'Flutter ${info.flutterVersion} • Dart ${info.dartVersion} • '
              '${info.channel}\n${info.sdkPath}';

    return MyTile(
      leading: _radio(isActive, primary),
      title: source.label + (isPinned ? '  (pinned)' : ''),
      subtitle: subtitle,
      trailing: _sourceAction(context, provider, source, info),
      onTap: provider.isBusy
          ? null
          : info != null
          ? () => provider.selectLocation(source)
          : source == FlutterSdkLocation.custom
          ? () => _pickCustomSdk(context, provider)
          : () => provider.detectSdk(),
    );
  }

  Widget? _sourceAction(
    BuildContext context,
    FlutterSdkProvider provider,
    FlutterSdkLocation source,
    FlutterSdkInfo? info,
  ) {
    final enabled = !provider.isBusy;
    return switch (source) {
      FlutterSdkLocation.custom => MyButton(
        label: info == null ? 'Choose...' : 'Change...',
        icon: NfIcons.folderOpen,
        height: 28,
        fontSize: 11.5,
        variant: MyButtonVariant.outline,
        onPressed: enabled ? () => _pickCustomSdk(context, provider) : null,
      ),
      _ => null,
    };
  }

  /// A filled ring for the SDK currently in charge.
  Widget _radio(bool isActive, Color primary) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? primary : primary.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: isActive
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
            )
          : null,
    );
  }

  /// Download and install progress: what step, how far, how fast, and the raw
  /// output of whatever subprocess is running.
  Widget _progress(
    BuildContext context,
    FlutterSdkProvider provider,
    Color primary,
  ) {
    final isDownloading = provider.phase == SdkInstallPhase.downloading;
    final percent = (provider.downloadProgress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                provider.phase.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              if (isDownloading) ...[
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    color: primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const Spacer(),
              MyButton(
                label: 'Cancel',
                icon: NfIcons.close,
                height: 26,
                fontSize: 11.5,
                variant: MyButtonVariant.outline,
                onPressed: provider.cancelInstall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: isDownloading && provider.totalBytes > 0
                ? provider.downloadProgress
                : null,
            backgroundColor: primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
          const SizedBox(height: 8),
          Text(
            isDownloading
                ? '${formatBytes(provider.receivedBytes)}'
                      ' of ${formatBytes(provider.totalBytes)}'
                      ' • ${formatBytes(provider.bytesPerSecond.round())}/s'
                      '${_remaining(provider.eta)}'
                : provider.statusMessage,
            style: TextStyle(
              fontSize: 11.5,
              color: primary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          LogConsole(lines: provider.installLog, height: 150),
        ],
      ),
    );
  }

  String _remaining(Duration? eta) {
    if (eta == null) return '';
    final minutes = eta.inMinutes;
    return minutes > 0
        ? ' • ~${minutes}m ${eta.inSeconds % 60}s left'
        : ' • ~${eta.inSeconds}s left';
  }

  Widget _banner(String error, Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(NfIcons.error, size: 15, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              error,
              style: TextStyle(
                fontSize: 11.5,
                color: primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeCard(FlutterSdkInfo sdk, Color primary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Flutter ${sdk.flutterVersion}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              _chip(sdk.channel, primary),
              const Spacer(),
              Text(
                sdk.location.label,
                style: TextStyle(
                  fontSize: 11,
                  color: primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dart SDK: ${sdk.dartVersion}'
            '${sdk.frameworkRevision == null ? '' : ' • framework ${sdk.frameworkRevision}'}',
            style: TextStyle(
              fontSize: 12,
              color: primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            sdk.sdkPath,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'FiraCode',
              color: primary.withValues(alpha: 0.5),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _channels(FlutterSdkProvider provider, FlutterSdkInfo sdk) {
    return MyTile(
      title: 'Release Channel',
      subtitle: 'Switching runs `flutter channel` and then upgrades in place.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final channel in ['stable', 'beta', 'master'])
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: MyButton(
                label: channel,
                variant: sdk.channel == channel
                    ? MyButtonVariant.primary
                    : MyButtonVariant.outline,
                height: 26,
                fontSize: 11.5,
                onPressed: sdk.channel == channel || provider.isBusy
                    ? null
                    : () => provider.switchChannel(channel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions(FlutterSdkProvider provider) {
    final enabled = !provider.isBusy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MyButton(
          label: 'Run Flutter Doctor',
          icon: NfIcons.info,
          variant: MyButtonVariant.secondary,
          onPressed: enabled ? () => provider.runDoctor() : null,
        ),
        MyButton(
          label: 'Upgrade SDK',
          icon: NfIcons.refresh,
          variant: MyButtonVariant.secondary,
          onPressed: enabled ? () => provider.upgradeSdk() : null,
        ),
      ],
    );
  }

  Widget _chip(String label, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }

  /// Asks which version to install, then installs it.
  Future<void> _chooseVersion(BuildContext context) async {
    final provider = context.read<FlutterSdkProvider>();
    final version = await showDialog<String>(
      context: context,
      builder: (_) => _VersionPicker(
        releases: provider.availableReleases(),
        installed: {for (final sdk in provider.bundledSdks) sdk.flutterVersion},
      ),
    );
    if (version != null) {
      await provider.downloadAndInstallBundledSdk(version: version);
    }
  }

  Future<void> _pickCustomSdk(
    BuildContext context,
    FlutterSdkProvider provider,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Flutter SDK Directory',
    );
    if (path != null && path.isNotEmpty) await provider.setCustomPath(path);
  }

  Future<bool> _confirmDeletion(BuildContext context, String version) async {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Delete Flutter $version?',
          style: TextStyle(color: primary, fontSize: 15),
        ),
        content: Text(
          'This removes the copy Bird installed. Other versions stay, and you '
          'can install it again at any time.',
          style: TextStyle(color: primary.withValues(alpha: 0.8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// The list of published Flutter versions, filtered as you type.
class _VersionPicker extends StatefulWidget {
  final Future<List<({String version, String channel})>> releases;
  final Set<String> installed;

  const _VersionPicker({required this.releases, required this.installed});

  @override
  State<_VersionPicker> createState() => _VersionPickerState();
}

class _VersionPickerState extends State<_VersionPicker> {
  final TextEditingController _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: primary.withValues(alpha: 0.18)),
      ),
      child: SizedBox(
        width: 460,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Install a Flutter version',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const Spacer(),
                  MiniButton(
                    icon: NfIcons.close,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                onChanged: (value) =>
                    setState(() => _filter = value.trim().toLowerCase()),
                style: TextStyle(fontSize: 12, color: primary),
                decoration: InputDecoration(
                  hintText: 'Version or channel, e.g. 3.44 or beta',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: primary.withValues(alpha: 0.4),
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<({String version, String channel})>>(
                  future: widget.releases,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final releases = [
                      for (final release in snapshot.data!)
                        if (_filter.isEmpty ||
                            '${release.version} ${release.channel}'.contains(
                              _filter,
                            ))
                          release,
                    ];
                    if (releases.isEmpty) {
                      return Center(
                        child: Text(
                          'No version matches "${_search.text.trim()}".',
                          style: TextStyle(
                            fontSize: 12,
                            color: primary.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: releases.length,
                      itemBuilder: (context, index) {
                        final release = releases[index];
                        final isInstalled = widget.installed.contains(
                          release.version,
                        );
                        return MyMenuItem(
                          icon: isInstalled ? NfIcons.check : NfIcons.flutter,
                          title: release.version,
                          trailing: Text(
                            isInstalled ? 'installed' : release.channel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary.withValues(alpha: 0.55),
                            ),
                          ),
                          result: isInstalled ? null : release.version,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
