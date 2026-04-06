import '../models/anonymous_user.dart';
import '../models/device_debug_info.dart';
import '../models/gatt_debug_info.dart';
import '../models/meal_realtime_snapshot.dart';
import '../models/meal_report.dart';
import '../models/reminder_settings.dart';
import '../models/trend_summary.dart';

class AppState {
  const AppState({
    required this.anonymousUser,
    required this.reminderSettings,
    required this.deviceDebugInfo,
    required this.gattDebugInfo,
    required this.realtimeSnapshot,
    required this.mealReport,
    required this.trendSummary,
    required this.todayMealCount,
  });

  final AnonymousUser anonymousUser;
  final ReminderSettings reminderSettings;
  final DeviceDebugInfo deviceDebugInfo;
  final GattDebugInfo gattDebugInfo;
  final MealRealtimeSnapshot realtimeSnapshot;
  final MealReport mealReport;
  final TrendSummary trendSummary;
  final int todayMealCount;

  AppState copyWith({
    AnonymousUser? anonymousUser,
    ReminderSettings? reminderSettings,
    DeviceDebugInfo? deviceDebugInfo,
    GattDebugInfo? gattDebugInfo,
    MealRealtimeSnapshot? realtimeSnapshot,
    MealReport? mealReport,
    TrendSummary? trendSummary,
    int? todayMealCount,
  }) {
    return AppState(
      anonymousUser: anonymousUser ?? this.anonymousUser,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      deviceDebugInfo: deviceDebugInfo ?? this.deviceDebugInfo,
      gattDebugInfo: gattDebugInfo ?? this.gattDebugInfo,
      realtimeSnapshot: realtimeSnapshot ?? this.realtimeSnapshot,
      mealReport: mealReport ?? this.mealReport,
      trendSummary: trendSummary ?? this.trendSummary,
      todayMealCount: todayMealCount ?? this.todayMealCount,
    );
  }
}
