import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/app_controller.dart';

class MealRealtimePage extends StatefulWidget {
  const MealRealtimePage({required this.controller, super.key});

  static const String routeName = '/meal-realtime';

  final AppController controller;

  @override
  State<MealRealtimePage> createState() => _MealRealtimePageState();
}

class _MealRealtimePageState extends State<MealRealtimePage> {
  int _lastHandledReminderPopupToken = 0;
  bool _isReminderDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.controller.ensureBhBleScanForRealtime());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final snapshot = widget.controller.state.realtimeSnapshot;
        final double engineWeightGram = snapshot.weightGram;
        _scheduleReminderPopupIfNeeded();
        return Scaffold(
          appBar: AppBar(title: const Text('用餐实时页')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('BLE 实时输入状态'),
                  subtitle: Text(
                    widget.controller.isBleScanning
                        ? '持续扫描中，等待 BH 重量广播持续刷新。'
                        : '当前未扫描，页面会自动尝试重新拉起 BLE 扫描。',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('本地写入状态'),
                  subtitle: Text(widget.controller.persistenceStatus),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('平滑处理状态'),
                  subtitle: Text(widget.controller.realtimeProcessingStatus),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('当前重量'),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '当前重量: ${engineWeightGram.toStringAsFixed(0)}g',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('MealEngine 当前重量'),
                  subtitle: const Text('主显示已经切回 MealEngine 输出。'),
                  trailing: Text('${engineWeightGram.toStringAsFixed(0)} g'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('BH 广播原始输入'),
                  subtitle: const Text('这条输入会先经过 5 点平滑，再交给 MealEngine。'),
                  trailing: Text(
                    '${snapshot.rawWeightGram.toStringAsFixed(0)} g',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('过去 60 秒有效夹菜次数'),
                  trailing: Text('${snapshot.pickCountLast60s} 次'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('平均单次夹菜量'),
                  trailing: Text('${snapshot.avgPickGrams.toStringAsFixed(1)} g'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('历史峰值夹菜频率'),
                  trailing: Text(
                    '${snapshot.peakPickFrequency.toStringAsFixed(1)} 次/分钟',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('是否过快'),
                  trailing: Text(snapshot.isTooFast ? '是' : '否'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('当前状态'),
                  subtitle: Text(snapshot.status),
                  trailing: Text('提醒 ${snapshot.reminderCount} 次'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('当前提醒判断'),
                  subtitle: Text(
                    '${widget.controller.latestReminderNote}\n方式：${widget.controller.latestReminderDeliverySummary}',
                  ),
                  trailing: Text(
                    widget.controller.latestReminderCanTrigger ? '应触发' : '不触发',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('引擎状态说明'),
                  subtitle: Text(snapshot.statusNote),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('最后更新时间'),
                  subtitle: Text(snapshot.lastUpdatedAt.toIso8601String()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleReminderPopupIfNeeded() {
    final int popupToken = widget.controller.pendingReminderPopupToken;
    final String? popupMessage = widget.controller.pendingReminderPopupMessage;
    if (_isReminderDialogVisible ||
        popupToken <= _lastHandledReminderPopupToken ||
        popupMessage == null ||
        popupMessage.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showReminderPopup(token: popupToken, message: popupMessage));
    });
  }

  Future<void> _showReminderPopup({
    required int token,
    required String message,
  }) async {
    if (!mounted || _isReminderDialogVisible) {
      return;
    }
    _isReminderDialogVisible = true;
    _lastHandledReminderPopupToken = token;
    widget.controller.markReminderPopupShown(token);
    bool dialogClosed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final NavigatorState navigator = Navigator.of(dialogContext);
        unawaited(
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (!mounted || dialogClosed) {
              return;
            }
            dialogClosed = true;
            if (navigator.canPop()) {
              navigator.pop();
            }
          }),
        );
        return AlertDialog(
          title: const Text('进食提醒'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                dialogClosed = true;
                navigator.pop();
              },
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );

    dialogClosed = true;
    _isReminderDialogVisible = false;
  }
}
