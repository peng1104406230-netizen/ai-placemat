import 'package:flutter/material.dart';

import '../providers/app_controller.dart';
import 'device_debug_page.dart';
import 'meal_realtime_page.dart';
import 'meal_report_page.dart';
import 'trend_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  static const String routeName = '/';

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final appState = controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('AI 智能餐垫')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('设备状态'),
                  subtitle: Text(
                    '${appState.deviceDebugInfo.deviceName} 已准备，RSSI ${appState.deviceDebugInfo.rssi} dBm',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('最近一餐摘要'),
                  subtitle: Text(appState.mealReport.summaryText),
                  trailing: Text(
                    '${appState.mealReport.intakeGrams.toStringAsFixed(0)} g',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('报告数据来源'),
                  subtitle: Text(appState.mealReport.reportSource),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('今日记录餐次'),
                  subtitle: Text('${appState.todayMealCount} 餐'),
                  trailing: Text(appState.anonymousUser.anonymousUserId),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  DeviceDebugPage.routeName,
                ),
                child: const Text('进入设备连接 / 蓝牙调试页'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  MealRealtimePage.routeName,
                ),
                child: const Text('进入用餐实时页'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  MealReportPage.routeName,
                ),
                child: const Text('进入单餐报告页'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  TrendSettingsPage.routeName,
                ),
                child: const Text('进入趋势 + 设置页'),
              ),
            ],
          ),
        );
      },
    );
  }
}
