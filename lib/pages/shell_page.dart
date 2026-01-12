import 'package:bird_ce/pages/code_page.dart';
import 'package:bird_ce/widgets/custom_titlebar.dart';
import 'package:bird_ce/pages/extensions_page.dart';
import 'package:bird_ce/widgets/my_icon_button.dart';
import 'package:bird_ce/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/styles/all.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int selectedIndex = 0;

  final pages = <Widget>[CodePage(), const ExtensionsPage()];

  void showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Tema Seç"),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView(
            children: builtinAllThemes.keys.map((themeName) {
              return ListTile(
                title: Text(themeName),
                onTap: () {
                  // Provider üzerinden global state'i güncelliyoruz
                  context.read<ThemeProvider>().setTheme(themeName);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        children: [
          CustomTitleBar(),
          Divider(height: 1, color: Colors.grey[900]),
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        spacing: 4,
                        children: [
                          MyIconButton(
                            onPressed: () {
                              setState(() {
                                selectedIndex = 0;
                              });
                            },
                            icon: PhosphorIcons.bird(PhosphorIconsStyle.thin),
                          ),
                          MyIconButton(
                            onPressed: () {
                              setState(() {
                                selectedIndex = 1;
                              });
                            },
                            icon: PhosphorIcons.feather(
                              PhosphorIconsStyle.thin,
                            ),
                          ),
                        ],
                      ),
                      MyIconButton(
                        icon: PhosphorIcons.palette(PhosphorIconsStyle.thin),
                        onPressed: () {
                          showThemePicker(context);
                        },
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey[900]),

                Expanded(child: pages[selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
