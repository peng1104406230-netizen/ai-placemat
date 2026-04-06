import 'package:flutter/material.dart';

import '../providers/app_controller.dart';

class MealReportPage extends StatelessWidget {
  const MealReportPage({required this.controller, super.key});

  static const String routeName = '/meal-report';

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final report = controller.state.mealReport;
        return Scaffold(
          appBar: AppBar(title: const Text('单餐报告页')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('数据来源'),
                  subtitle: Text(report.reportSource),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('本餐时长'),
                  trailing: Text('${report.durationSeconds ~/ 60} 分钟'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('总进食克数'),
                  trailing: Text('${report.intakeGrams.toStringAsFixed(0)} g'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('平均夹菜频率'),
                  trailing: Text('${report.avgSpeed.toStringAsFixed(1)} 次/分钟'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('峰值夹菜频率'),
                  trailing: Text('${report.peakSpeed.toStringAsFixed(1)} 次/分钟'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('提醒次数'),
                  trailing: Text('${report.reminderCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('一句话总结'),
                  subtitle: Text(report.summaryText),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('AI 建议展示位'),
                  subtitle: Text(
                    report.aiSuggestion ?? 'TODO: 当前阶段只保留展示位，不接 AI。',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
