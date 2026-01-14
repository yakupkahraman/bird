import 'package:bird_ce/planguage_provider.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguagesPage extends StatelessWidget {
  const LanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlanguageProvider>(
        builder: (context, languageProvider, child) {
          final currentLanguage = languageProvider.currentLanguage;
          final availableLanguages = languageProvider.availableLanguages;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programming Languages',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current: ${currentLanguage.displayName}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: availableLanguages.length,
                  itemBuilder: (context, index) {
                    final language = availableLanguages[index];
                    final isSelected = language.name == currentLanguage.name;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      leading: FileIcon(language.extensions.first, size: 18),
                      title: Text(
                        language.displayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      // subtitle: Text(
                      //   'Extensions: ${language.extensions.join(', ')}',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: Theme.of(context).colorScheme.onSurfaceVariant,
                      //   ),
                      // ),
                      onTap: () {
                        languageProvider.setLanguage(language);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
