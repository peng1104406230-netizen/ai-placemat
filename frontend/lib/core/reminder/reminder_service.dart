import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/reminder_settings.dart';
import '../../models/meal_realtime_snapshot.dart';

class ReminderPreview {
  const ReminderPreview({
    required this.canTrigger,
    required this.note,
    required this.message,
    required this.shouldVibrate,
    required this.shouldPopup,
    required this.shouldSpeak,
  });

  final bool canTrigger;
  final String note;
  final String message;
  final bool shouldVibrate;
  final bool shouldPopup;
  final bool shouldSpeak;

  String get deliverySummary {
    final List<String> labels = <String>[
      if (shouldVibrate) '震动',
      if (shouldPopup) '弹窗',
      if (shouldSpeak) '语音',
    ];
    return labels.isEmpty ? '未选择提醒方式' : labels.join(' / ');
  }
}

class ReminderService {
  ReminderService();

  static const String defaultReminderText = '请放慢进食速度';

  FlutterTts? _tts;
  bool _ttsConfigured = false;

  factory ReminderService.basic() {
    return ReminderService();
  }

  ReminderPreview preview(ReminderSettings settings) {
    final bool inQuietHours = _isWithinQuietHours(settings.quietHours);
    final String message = _normalizeMessage(settings.reminderText);
    final bool hasAnyMethod = settings.hasAnyDeliveryMethod;
    final String deliverySummary = _buildDeliverySummary(
      vibrationEnabled: settings.vibrationEnabled,
      popupEnabled: settings.popupEnabled,
      voiceEnabled: settings.voiceEnabled,
    );
    return ReminderPreview(
      canTrigger: false,
      note: _buildSettingsPreviewNote(
        reminderEnabled: settings.reminderEnabled,
        hasAnyMethod: hasAnyMethod,
        inQuietHours: inQuietHours,
        deliverySummary: deliverySummary,
      ),
      message: message,
      shouldVibrate:
          settings.reminderEnabled && settings.vibrationEnabled && !inQuietHours,
      shouldPopup:
          settings.reminderEnabled && settings.popupEnabled && !inQuietHours,
      shouldSpeak:
          settings.reminderEnabled && settings.voiceEnabled && !inQuietHours,
    );
  }

  ReminderPreview evaluate(
    ReminderSettings settings,
    MealRealtimeSnapshot snapshot,
  ) {
    final bool inQuietHours = _isWithinQuietHours(settings.quietHours);
    final bool hasAnyMethod = settings.hasAnyDeliveryMethod;
    final bool isEatingPhase = snapshot.status == 'eating';
    final bool canTrigger =
        settings.reminderEnabled &&
        hasAnyMethod &&
        !inQuietHours &&
        isEatingPhase &&
        snapshot.isTooFast;
    final String deliverySummary = _buildDeliverySummary(
      vibrationEnabled: settings.vibrationEnabled,
      popupEnabled: settings.popupEnabled,
      voiceEnabled: settings.voiceEnabled,
    );
    final String message = _normalizeMessage(settings.reminderText);
    return ReminderPreview(
      canTrigger: canTrigger,
      note: _buildPreviewNote(
        reminderEnabled: settings.reminderEnabled,
        hasAnyMethod: hasAnyMethod,
        inQuietHours: inQuietHours,
        isEatingPhase: isEatingPhase,
        snapshotAllowsTrigger: snapshot.isTooFast,
        deliverySummary: deliverySummary,
      ),
      message: message,
      shouldVibrate: canTrigger && settings.vibrationEnabled,
      shouldPopup: canTrigger && settings.popupEnabled,
      shouldSpeak: canTrigger && settings.voiceEnabled,
    );
  }

  Future<void> executeNonVisual(ReminderPreview preview) async {
    if (!preview.canTrigger) {
      return;
    }

    if (preview.shouldVibrate) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {
        // 保持提醒主链路继续运行，不让震动失败打断其他提醒方式。
      }
    }

    if (preview.shouldSpeak) {
      await _speak(preview.message);
    }
  }

  Future<String> previewVoice(String text) async {
    return _speak(_normalizeMessage(text));
  }

  Future<void> dispose() async {
    if (_tts == null) {
      return;
    }
    try {
      await _tts!.stop();
    } catch (_) {
      // 当前阶段只做本地提醒，不因为释放失败影响页面退出。
    }
  }

  bool _isWithinQuietHours(QuietHours quietHours) {
    if (!quietHours.enabled) {
      return false;
    }

    final List<String> startTokens = quietHours.start.split(':');
    final List<String> endTokens = quietHours.end.split(':');
    if (startTokens.length != 2 || endTokens.length != 2) {
      return false;
    }

    final DateTime now = DateTime.now();
    final int nowMinutes = now.hour * 60 + now.minute;
    final int startMinutes =
        (int.tryParse(startTokens[0]) ?? 0) * 60 +
        (int.tryParse(startTokens[1]) ?? 0);
    final int endMinutes =
        (int.tryParse(endTokens[0]) ?? 0) * 60 +
        (int.tryParse(endTokens[1]) ?? 0);

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  String _buildDeliverySummary({
    required bool vibrationEnabled,
    required bool popupEnabled,
    required bool voiceEnabled,
  }) {
    final List<String> labels = <String>[
      if (vibrationEnabled) '震动',
      if (popupEnabled) '弹窗',
      if (voiceEnabled) '语音',
    ];
    return labels.isEmpty ? '未选择提醒方式' : labels.join(' / ');
  }

  String _buildPreviewNote({
    required bool reminderEnabled,
    required bool hasAnyMethod,
    required bool inQuietHours,
    required bool isEatingPhase,
    required bool snapshotAllowsTrigger,
    required String deliverySummary,
  }) {
    if (!reminderEnabled) {
      return '提醒开关已关闭。';
    }
    if (!hasAnyMethod) {
      return '当前未选择任何提醒方式。';
    }
    if (inQuietHours) {
      return '当前处于静音时段，本地提醒将保持静默。';
    }
    if (!isEatingPhase) {
      return '当前仍在 preparing 阶段，暂不提醒。';
    }
    if (!snapshotAllowsTrigger) {
      return '当前夹菜频率正常，暂不提醒。已启用方式：$deliverySummary。';
    }
    return '已触发提醒：$deliverySummary。';
  }

  String _buildSettingsPreviewNote({
    required bool reminderEnabled,
    required bool hasAnyMethod,
    required bool inQuietHours,
    required String deliverySummary,
  }) {
    if (!reminderEnabled) {
      return '提醒开关已关闭。';
    }
    if (!hasAnyMethod) {
      return '当前未选择任何提醒方式。';
    }
    if (inQuietHours) {
      return '当前处于静音时段，本地提醒将保持静默。';
    }
    return '当前提醒设置已生效：$deliverySummary。';
  }

  String _normalizeMessage(String rawText) {
    final String trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return defaultReminderText;
    }
    return trimmed;
  }

  Future<String> _speak(String text) async {
    final FlutterTts tts;
    try {
      tts = await _ensureTts();
    } catch (error) {
      final String reason = '$error';
      debugPrint('[ReminderTTS] unavailable: $reason');
      return '语音试播失败：$reason';
    }
    try {
      debugPrint('[ReminderTTS] speak text="$text"');
      await tts.stop();
      final dynamic result = await tts.speak(text, focus: true);
      debugPrint('[ReminderTTS] speak result=$result');
      return '试播已发起，请检查系统音量和 TTS 引擎。';
    } catch (error) {
      debugPrint('[ReminderTTS] speak failed: $error');
      return '语音试播失败：$error';
    }
  }

  Future<FlutterTts> _ensureTts() async {
    _tts ??= FlutterTts();
    if (_ttsConfigured) {
      return _tts!;
    }

    _tts!.setStartHandler(() {
      debugPrint('[ReminderTTS] start');
    });
    _tts!.setCompletionHandler(() {
      debugPrint('[ReminderTTS] completed');
    });
    _tts!.setCancelHandler(() {
      debugPrint('[ReminderTTS] canceled');
    });
    _tts!.setErrorHandler((dynamic message) {
      debugPrint('[ReminderTTS] error: $message');
    });

    try {
      final dynamic engines = await _tts!.getEngines;
      debugPrint('[ReminderTTS] engines=$engines');
    } catch (error) {
      debugPrint('[ReminderTTS] getEngines failed: $error');
    }

    debugPrint('[ReminderTTS] using system default language/voice');

    try {
      await _tts!.awaitSpeakCompletion(true);
    } catch (error) {
      debugPrint('[ReminderTTS] awaitSpeakCompletion failed: $error');
    }

    try {
      await _tts!.setAudioAttributesForNavigation();
    } catch (error) {
      debugPrint('[ReminderTTS] setAudioAttributesForNavigation failed: $error');
    }

    try {
      await _tts!.setQueueMode(0);
    } catch (error) {
      debugPrint('[ReminderTTS] setQueueMode failed: $error');
    }

    try {
      await _tts!.setSpeechRate(0.48);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
    } catch (error) {
      debugPrint('[ReminderTTS] configure failed: $error');
    }
    _ttsConfigured = true;
    return _tts!;
  }
}
