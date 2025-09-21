import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'l10n/app_localizations.dart';

import 'auth.dart';
import 'auth_provider.dart';
import 'editprofile_page.dart';
import 'constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller =
    TextEditingController(text: AppConstants.ngrokId);
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    TextStyle titleStyle = theme.textTheme.titleMedium!.copyWith(color: cs.onSurface);
    TextStyle itemStyle  = theme.textTheme.bodyMedium!.copyWith(color: cs.onSurface);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(loc.theme, style: titleStyle),
                  const SizedBox(height: 8),
                  DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    dropdownColor: cs.surface,
                    style: itemStyle,
                    onChanged: (val) => val != null ? settings.setThemeMode(val) : null,
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text(loc.systemTheme, style: itemStyle)),
                      DropdownMenuItem(value: ThemeMode.light,  child: Text(loc.lightTheme,  style: itemStyle)),
                      DropdownMenuItem(value: ThemeMode.dark,   child: Text(loc.darkTheme,   style: itemStyle)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(loc.language, style: titleStyle),
                  const SizedBox(height: 8),
                  DropdownButton<Locale>(
                    value: settings.locale,
                    dropdownColor: cs.surface,
                    style: itemStyle,
                    onChanged: (val) => val != null ? settings.setLocale(val) : null,
                    items: [
                      DropdownMenuItem(value: const Locale('en'), child: Text(loc.english, style: itemStyle)),
                      DropdownMenuItem(value: const Locale('vi'), child: Text(loc.vietnamese, style: itemStyle)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(loc.fontSize, style: titleStyle),
                  const SizedBox(height: 8),
                  Slider(
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    value: settings.fontScale,
                    activeColor: cs.primary,
                    inactiveColor: cs.onSurface.withAlpha((255 * 0.2).round()),
                    onChanged: (v) => settings.setFontScale(v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_backup_restore),
                    label: Text(loc.setDefault),
                    onPressed: () {
                      settings.setThemeMode(ThemeMode.system);
                      settings.setLocale(const Locale('en'));
                      settings.setFontScale(1.0);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (auth.isLoggedIn) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: Text(loc.editProfile),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfilePage()),
                        );
                      },
                    ),
                  ],
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Ngrok ID',
                      hintText: 'Ví dụ: ${AppConstants.ngrokId}',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      AppConstants.setNgrokId(controller.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu ngrok ID mới')),
                      );
                    },
                    child: Text(loc.save),
                  ),
                  const SizedBox(height: 20),
                  Text('URL hiện tại: ${AppConstants.apiBaseUrl}'),
                ],
              ),
            ),
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(loc.logout),
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                          (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
