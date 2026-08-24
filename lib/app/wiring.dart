import 'package:bird/features/editor/file_provider.dart';
import 'package:bird/features/editor/tab_opener.dart';
import 'package:bird/features/layout/panes_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:bird/features/terminal/terminal_provider.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Every long-lived object in the app, wired in one place.
///
/// Order matters: a proxy provider can only read what is already above it.
List<SingleChildWidget> appProviders() => [
  ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
    create: (_) => ThemeProvider(),
    update: (_, settings, themeProvider) =>
        themeProvider!..attachSettings(settings),
  ),
  ChangeNotifierProxyProvider<SettingsProvider, FlutterSdkProvider>(
    create: (_) => FlutterSdkProvider(),
    update: (_, settings, sdk) => sdk!..attachSettings(settings),
  ),
  ChangeNotifierProxyProvider<FlutterSdkProvider, LspProvider>(
    create: (_) => LspProvider(),
    update: (_, sdk, lsp) => lsp!..attachSdk(sdk),
  ),
  ChangeNotifierProxyProvider2<LspProvider, SettingsProvider, FileProvider>(
    create: (_) => FileProvider(),
    update: (_, lsp, settings, fileProvider) => fileProvider!
      ..attachLsp(lsp)
      ..attachSettings(settings),
  ),
  ProxyProvider<FileProvider, TabOpener>(
    update: (_, files, _) => files.openFile,
  ),
  ChangeNotifierProxyProvider<FlutterSdkProvider, TerminalProvider>(
    create: (_) => TerminalProvider(),
    update: (_, sdk, terminal) => terminal!..attachSdk(sdk),
  ),
  ChangeNotifierProvider(create: (_) => PanesProvider()),
];
