import 'package:bird/features/editor/editor_provider.dart';
import 'package:bird/features/editor/tab_opener.dart';
import 'package:bird/features/layout/panes_provider.dart';
import 'package:bird/features/lsp/lsp_provider.dart';
import 'package:bird/features/notifications/notifications_provider.dart';
import 'package:bird/features/sdk/flutter_sdk_provider.dart';
import 'package:bird/features/search/file_index_provider.dart';
import 'package:bird/features/search/search_provider.dart';
import 'package:bird/features/settings/settings_provider.dart';
import 'package:bird/features/terminal/terminal_provider.dart';
import 'package:bird/features/workspace/workspace_provider.dart';
import 'package:bird/features/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Every long-lived object in the app, wired in one place.
///
/// Order matters: a proxy provider can only read what is already above it.
List<SingleChildWidget> appProviders() => [
  ChangeNotifierProvider(create: (_) => NotificationsProvider()),
  ChangeNotifierProxyProvider<NotificationsProvider, SettingsProvider>(
    create: (_) => SettingsProvider(),
    update: (_, notifications, settings) =>
        settings!..attachNotifications(notifications),
  ),
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
  ChangeNotifierProxyProvider2<
    LspProvider,
    SettingsProvider,
    WorkspaceProvider
  >(
    create: (_) => WorkspaceProvider(),
    update: (_, lsp, settings, workspace) => workspace!
      ..attachLsp(lsp)
      ..attachSettings(settings),
  ),
  ChangeNotifierProxyProvider3<
    LspProvider,
    WorkspaceProvider,
    NotificationsProvider,
    EditorProvider
  >(
    create: (_) => EditorProvider(),
    update: (_, lsp, workspace, notifications, editor) => editor!
      ..attachLsp(lsp)
      ..attachWorkspace(workspace)
      ..attachNotifications(notifications),
  ),
  ChangeNotifierProxyProvider2<
    WorkspaceProvider,
    NotificationsProvider,
    SearchProvider
  >(
    create: (_) => SearchProvider(),
    update: (_, workspace, notifications, search) => search!
      ..attachWorkspace(workspace)
      ..attachNotifications(notifications),
  ),
  ChangeNotifierProxyProvider2<
    WorkspaceProvider,
    NotificationsProvider,
    FileIndexProvider
  >(
    create: (_) => FileIndexProvider(),
    update: (_, workspace, notifications, index) => index!
      ..attachWorkspace(workspace)
      ..attachNotifications(notifications),
  ),
  ProxyProvider<EditorProvider, TabOpener>(
    update: (_, editor, _) => editor.openFile,
  ),
  ChangeNotifierProxyProvider<FlutterSdkProvider, TerminalProvider>(
    create: (_) => TerminalProvider(),
    update: (_, sdk, terminal) => terminal!..attachSdk(sdk),
  ),
  ChangeNotifierProvider(create: (_) => PanesProvider()),
];
