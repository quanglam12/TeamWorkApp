import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
            // đổi withOpacity -> withValues
            inactiveColor: cs.onSurface.withValues(alpha: 0.2),
            onChanged: (v) => settings.setFontScale(v),
          ),
        ],
      ),
    );
  }
}