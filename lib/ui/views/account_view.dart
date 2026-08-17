import 'package:bird/widgets/my_button.dart';
import 'package:bird/widgets/my_tile.dart';
import 'package:bird/widgets/nf_icons.dart';
import 'package:flutter/material.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accounts & Authentication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your connected developer accounts, package services, and git credentials.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: primary.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 24),

                MyTile(
                  icon: NfIcons.github,
                  title: 'GitHub',
                  subtitle: 'Sign in to access remote repositories, Gists, and GitHub integration.',
                  trailing: MyButton.outline(
                    label: 'Sign In',
                    width: 90,
                    height: 28,
                    fontSize: 11.5,
                    onPressed: () {},
                  ),
                ),

                MyTile(
                  icon: NfIcons.dart,
                  title: 'pub.dev',
                  subtitle: 'Authenticate with pub.dev to publish and manage Dart & Flutter packages.',
                  trailing: MyButton.outline(
                    label: 'Sign In',
                    width: 90,
                    height: 28,
                    fontSize: 11.5,
                    onPressed: () {},
                  ),
                ),

                MyTile(
                  icon: NfIcons.gitBranch,
                  title: 'Git Credentials & Author Identity',
                  subtitle: 'Configure Git commit author details and authentication keys.',
                  trailing: MyButton.secondary(
                    label: 'Configure',
                    width: 90,
                    height: 28,
                    fontSize: 11.5,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
