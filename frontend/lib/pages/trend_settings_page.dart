import 'package:flutter/material.dart';

import '../models/reminder_settings.dart';
import '../providers/app_controller.dart';

class TrendSettingsPage extends StatefulWidget {
  const TrendSettingsPage({required this.controller, super.key});

  static const String routeName = '/trend-settings';

  final AppController controller;

  @override
  State<TrendSettingsPage> createState() => _TrendSettingsPageState();
}

class _TrendSettingsPageState extends State<TrendSettingsPage> {
  late final TextEditingController _frequencyController;
  late final TextEditingController _reminderTextController;
  late final TextEditingController _quietHoursStartController;
  late final TextEditingController _quietHoursEndController;
  bool _reminderEnabled = true;
  bool _vibrationEnabled = true;
  bool _popupEnabled = true;
  bool _voiceEnabled = true;
  bool _quietHoursEnabled = true;
  double _maxPicksPerMinute = 8;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.state.reminderSettings;
    _frequencyController = TextEditingController(
      text: settings.reminderFrequency.toString(),
    );
    _reminderTextController = TextEditingController(text: settings.reminderText);
    _quietHoursStartController = TextEditingController(
      text: settings.quietHours.start,
    );
    _quietHoursEndController = TextEditingController(
      text: settings.quietHours.end,
    );
    _reminderEnabled = settings.reminderEnabled;
    _vibrationEnabled = settings.vibrationEnabled;
    _popupEnabled = settings.popupEnabled;
    _voiceEnabled = settings.voiceEnabled;
    _quietHoursEnabled = settings.quietHours.enabled;
    _maxPicksPerMinute = settings.maxPicksPerMinute.toDouble();
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _reminderTextController.dispose();
    _quietHoursStartController.dispose();
    _quietHoursEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final trend = widget.controller.state.trendSummary;
        final settings = widget.controller.state.reminderSettings;

        return Scaffold(
          appBar: AppBar(title: const Text('趋势 + 设置页')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text('趋势'),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('最近 7 天平均夹菜频率'),
                  trailing: Text('${trend.avgSpeed.toStringAsFixed(1)} 次/分钟'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('最近 7 天快吃次数'),
                  trailing: Text('${trend.fastMealCount}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('改善率'),
                  trailing: Text(
                    '${(trend.improvementRate * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('趋势总结'),
                  subtitle: Text(trend.summaryText),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('AI 趋势总结展示位'),
                  subtitle: Text(
                    trend.aiTrendInsight ?? 'TODO: 当前阶段只保留展示位，不接 AI。',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('设置'),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _reminderEnabled,
                onChanged: (bool value) {
                  setState(() => _reminderEnabled = value);
                },
                title: const Text('提醒开关'),
              ),
              TextField(
                controller: _frequencyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '提醒频率（秒）',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '提醒阈值：${_maxPicksPerMinute.toStringAsFixed(0)} 次/分钟',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _maxPicksPerMinute,
                        min: 3,
                        max: 20,
                        divisions: 17,
                        label:
                            '${_maxPicksPerMinute.toStringAsFixed(0)} 次/分钟',
                        onChanged: (double value) {
                          setState(() => _maxPicksPerMinute = value);
                        },
                      ),
                      const Text(
                        '过去 60 秒内有效夹菜次数超过这个阈值时，MealEngine 会认定当前吃得过快。',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: <Widget>[
                    CheckboxListTile(
                      value: _vibrationEnabled,
                      onChanged: (bool? value) {
                        setState(() => _vibrationEnabled = value ?? false);
                      },
                      title: const Text('提醒方式：震动'),
                      subtitle: const Text('优先用 HapticFeedback 给前台用户即时提醒。'),
                    ),
                    CheckboxListTile(
                      value: _popupEnabled,
                      onChanged: (bool? value) {
                        setState(() => _popupEnabled = value ?? false);
                      },
                      title: const Text('提醒方式：弹窗提示'),
                      subtitle: const Text('触发提醒时在前台弹出文本提示。'),
                    ),
                    CheckboxListTile(
                      value: _voiceEnabled,
                      onChanged: (bool? value) {
                        setState(() => _voiceEnabled = value ?? false);
                      },
                      title: const Text('提醒方式：语音播报（TTS）'),
                      subtitle: const Text('使用系统 TTS 播报提醒内容。'),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('当前提醒方式'),
                subtitle: Text(_buildReminderMethodSummary()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reminderTextController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '语音内容',
                  helperText: '弹窗提示会复用这段文字，默认“请放慢进食速度”。',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ScaffoldMessengerState messenger =
                        ScaffoldMessenger.of(context);
                    final String result = await widget.controller
                        .previewReminderVoiceText(
                          _reminderTextController.text.trim(),
                        );
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  },
                  icon: const Icon(Icons.record_voice_over_outlined),
                  label: const Text('试播语音'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '试播不依赖当前是否勾选语音播报，方便先检查手机 TTS 是否正常。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              SwitchListTile(
                value: _quietHoursEnabled,
                onChanged: (bool value) {
                  setState(() => _quietHoursEnabled = value);
                },
                title: const Text('启用静音时段'),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _quietHoursStartController,
                      decoration: const InputDecoration(labelText: '开始时间'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _quietHoursEndController,
                      decoration: const InputDecoration(labelText: '结束时间'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.controller.isSavingSettings
                    ? null
                    : () => _saveSettings(context),
                child: Text(
                  widget.controller.isSavingSettings ? '保存中...' : '保存本地设置',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('当前本地缓存状态'),
                subtitle: Text(settings.syncState),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSettings(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int reminderFrequency =
        int.tryParse(_frequencyController.text.trim()) ?? 180;
    final ReminderSettings updated = widget.controller.state.reminderSettings
        .copyWith(
          reminderEnabled: _reminderEnabled,
          reminderFrequency: reminderFrequency,
          maxPicksPerMinute: _maxPicksPerMinute.round(),
          reminderText: _reminderTextController.text.trim(),
          vibrationEnabled: _vibrationEnabled,
          popupEnabled: _popupEnabled,
          voiceEnabled: _voiceEnabled,
          quietHours: widget.controller.state.reminderSettings.quietHours.copyWith(
            enabled: _quietHoursEnabled,
            start: _quietHoursStartController.text.trim(),
            end: _quietHoursEndController.text.trim(),
          ),
        );

    await widget.controller.saveReminderSettings(updated);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('本地设置已保存')),
    );
  }

  String _buildReminderMethodSummary() {
    final List<String> labels = <String>[
      if (_vibrationEnabled) '震动',
      if (_popupEnabled) '弹窗',
      if (_voiceEnabled) '语音',
    ];
    if (labels.isEmpty) {
      return '当前未选择提醒方式，提醒不会触发。';
    }
    return labels.join(' / ');
  }
}
