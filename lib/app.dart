import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'services/speech_service.dart';
import 'services/location_service.dart';
import 'services/assistant_service.dart';
import 'services/incident_service.dart';
import 'services/saved_locations_service.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';
import 'screens/splash_screen.dart';

class SurakshaApp extends StatelessWidget {
  const SurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<LocalizationService>(create: (_) => LocalizationService()),
        ChangeNotifierProvider<IncidentService>(create: (_) => IncidentService()),
        ChangeNotifierProvider<SavedLocationsService>(create: (_) => SavedLocationsService()),
        ChangeNotifierProvider<SpeechService>(create: (_) => SpeechService()),
        ChangeNotifierProvider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProxyProvider<SpeechService, AssistantService>(
          create: (ctx) => AssistantService(
            speechService: Provider.of<SpeechService>(ctx, listen: false),
          ),
          update: (ctx, speech, previous) =>
              previous ?? AssistantService(speechService: speech),
        ),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, locService, child) {
          // Brand Colors
          const primaryIndigo = Color(0xFF1A237E);
          const accentTeal = Color(0xFF00897B);

          // Dark Palette: Brand Navy (matching suraksha_splash.png)
          const darkBackground = Color(0xFF0D1326);
          const darkSurface = Color(0xFF141C33);
          const darkCard = Color(0xFF18223E);
          const darkBorder = Color(0xFF223055);

          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            locale: locService.currentLocale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('te', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: themeService.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: primaryIndigo,
              scaffoldBackgroundColor: const Color(0xFFF5F7FA),
              colorScheme: const ColorScheme.light(
                primary: primaryIndigo,
                onPrimary: Colors.white,
                secondary: accentTeal,
                onSecondary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1E293B),
                error: Color(0xFFC62828),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryIndigo,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFE2E8F0),
                thickness: 0.8,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF3949AB),
              scaffoldBackgroundColor: darkBackground,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3949AB),
                onPrimary: Colors.white,
                secondary: accentTeal,
                onSecondary: Colors.white,
                surface: darkSurface,
                onSurface: Color(0xFFF1F5F9),
                error: Color(0xFFEF5350),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: darkBackground,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                color: darkCard,
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: darkBorder, width: 0.8),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: darkSurface,
                surfaceTintColor: Colors.transparent,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: darkSurface,
                surfaceTintColor: Colors.transparent,
              ),
              dividerTheme: const DividerThemeData(
                color: darkBorder,
                thickness: 0.8,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
