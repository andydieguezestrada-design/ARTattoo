import 'package:flutter/material.dart';

import 'data/academy_repository.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

class ArtattooAcademyApp extends StatefulWidget {
  const ArtattooAcademyApp({super.key});

  @override
  State<ArtattooAcademyApp> createState() => _ArtattooAcademyAppState();
}

class _ArtattooAcademyAppState extends State<ArtattooAcademyApp> {
  late final AcademyRepository repository;

  @override
  void initState() {
    super.initState();
    repository = AcademyRepository();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeMode = await SettingsService.getThemeMode();
    final animations = await SettingsService.getAnimationsEnabled();
    SettingsService.themeModeNotifier.value = themeMode;
    SettingsService.animationsNotifier.value = animations;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'ARTattoo Academy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: HomeScreen(
            repository: repository,
          ),
        );
      },
    );
  }
}
