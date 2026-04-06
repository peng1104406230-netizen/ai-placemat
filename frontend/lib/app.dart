import 'package:flutter/material.dart';

import 'pages/device_debug_page.dart';
import 'pages/home_page.dart';
import 'pages/meal_realtime_page.dart';
import 'pages/meal_report_page.dart';
import 'pages/trend_settings_page.dart';
import 'providers/app_controller.dart';

class AiPlacematApp extends StatelessWidget {
  const AiPlacematApp({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'AI 智能餐垫',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2D6A4F),
            ),
            useMaterial3: true,
          ),
          home: _buildHome(),
          routes: <String, WidgetBuilder>{
            DeviceDebugPage.routeName: (_) => DeviceDebugPage(
              controller: controller,
            ),
            MealRealtimePage.routeName: (_) => MealRealtimePage(
              controller: controller,
            ),
            MealReportPage.routeName: (_) => MealReportPage(
              controller: controller,
            ),
            TrendSettingsPage.routeName: (_) => TrendSettingsPage(
              controller: controller,
            ),
          },
        );
      },
    );
  }

  Widget _buildHome() {
    if (!controller.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(controller.errorMessage!),
          ),
        ),
      );
    }

    return HomePage(controller: controller);
  }
}
