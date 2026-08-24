import 'package:bird/app/app.dart';
import 'package:bird/app/wiring.dart';
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
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MultiProvider(providers: appProviders(), child: const MyApp()));
}
