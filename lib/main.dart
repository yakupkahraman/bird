import 'package:bird/file_provider.dart';
import 'package:bird/pages/shell_page.dart';
import 'package:bird/planguage_provider.dart';
import 'package:bird/terminal_provider.dart';
import 'package:bird/theme/theme.dart';
import 'package:bird/theme/theme_provider.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await RustLib.init();

  WindowOptions windowOptions = WindowOptions(
    title: 'Bird',
    size: Size(800, 600),
    minimumSize: Size(400, 200),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );

    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => PlanguageProvider()),
        ChangeNotifierProvider(create: (_) => TerminalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bird',
      theme: appTheme(themeProvider),
      home: ShellPage(),
    );
  }
}
