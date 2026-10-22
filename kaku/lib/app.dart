import 'package:flutter/material.dart';
import 'core/common/constants/app_constants.dart';
import 'core/routes/routes.dart';
import 'core/theme/themes.dart';

class KakuApp extends StatelessWidget {
  const KakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, 
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      routerConfig: appRouter,
    );
  }
}
