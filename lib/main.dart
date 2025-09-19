import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';
import 'auth.dart';
import 'auth_provider.dart';
import 'homepage.dart';

import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadSavedLogin();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => authProvider),
      ],
      child: const MyApp(),
    ),
  );
}

final lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
final darkColorScheme  = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

ThemeData buildLightTheme() {
  return ThemeData.from(
    colorScheme: lightColorScheme,
    useMaterial3: true,
  ).copyWith(
    textTheme: ThemeData.light().textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primary,
      titleTextStyle: TextStyle(
        color: lightColorScheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: lightColorScheme.onPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(color: lightColorScheme.onPrimaryContainer),
      backgroundColor: lightColorScheme.primaryContainer,
    ),
    // 👇 thêm style chung cho TextField
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: lightColorScheme.onSurface),
      hintStyle: TextStyle(color: lightColorScheme.onSurface.withAlpha((255 * 0.8).round())),
      floatingLabelStyle: TextStyle(color: lightColorScheme.primary),
      border: const OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData.from(
    colorScheme: darkColorScheme,
    useMaterial3: true,
  ).copyWith(
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: darkColorScheme.onSurface,
      displayColor: darkColorScheme.onSurface,
    ),
    scaffoldBackgroundColor: darkColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      titleTextStyle: TextStyle(
        color: darkColorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: darkColorScheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(color: darkColorScheme.onPrimary),
      backgroundColor: darkColorScheme.primary,
    ),
    // 👇 style TextField cho dark
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: darkColorScheme.onSurface),
      hintStyle: TextStyle(color: darkColorScheme.onSurface.withAlpha((255 * 0.8).round())),
      floatingLabelStyle: TextStyle(color: darkColorScheme.primary),
      border: const OutlineInputBorder(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Teamwork App',
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [ Locale('en'), Locale('vi') ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // áp scale chữ toàn app
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child!,
              );
            },
            home: auth.isLoggedIn ? const HomePage() : const AuthPage(),
          );
        },
      ),
    );
  }
}
