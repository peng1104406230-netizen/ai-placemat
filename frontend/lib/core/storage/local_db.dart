import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/meal_report.dart';
import '../../models/trend_summary.dart';
import 'local_db_contract.dart';

class LocalDb implements MealRecordStore, WeightSampleStore, ReminderEventStore {
  LocalDb();

  static const String _legacyDemoMealPrefix = 'local-';

  Database? _database;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final DatabaseFactory factory = _resolveDatabaseFactory();
    final String databasesPath = await factory.getDatabasesPath();
    final String databasePath = path.join(databasesPath, 'ai_placemat.db');

    _database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE meal_records (
              meal_id TEXT PRIMARY KEY,
              anonymous_user_id TEXT NOT NULL,
              started_at TEXT NOT NULL,
              ended_at TEXT NOT NULL,
              intake_grams REAL NOT NULL,
              avg_speed REAL NOT NULL,
              peak_speed REAL NOT NULL,
              reminder_count INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE weight_samples (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              meal_id TEXT NOT NULL,
              weight_gram REAL NOT NULL,
              recorded_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE reminder_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              meal_id TEXT NOT NULL,
              reminder_text TEXT NOT NULL,
              vibration_enabled INTEGER NOT NULL,
              popup_enabled INTEGER NOT NULL,
              voice_enabled INTEGER NOT NULL,
              triggered_at TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE reminder_events ADD COLUMN vibration_enabled INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE reminder_events ADD COLUMN popup_enabled INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      ),
    );

    return _database!;
  }

  Future<void> deleteLegacyDemoMealsForUser({
    required String anonymousUserId,
  }) async {
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      'meal_records',
      columns: <String>['meal_id'],
      where: 'anonymous_user_id = ? AND meal_id LIKE ?',
      whereArgs: <Object?>[
        anonymousUserId,
        '$_legacyDemoMealPrefix%',
      ],
    );
    if (rows.isEmpty) {
      return;
    }

    final Batch batch = db.batch();
    for (final Map<String, Object?> row in rows) {
      final String mealId = row['meal_id']! as String;
      batch.delete(
        'weight_samples',
        where: 'meal_id = ?',
        whereArgs: <Object?>[mealId],
      );
      batch.delete(
        'reminder_events',
        where: 'meal_id = ?',
        whereArgs: <Object?>[mealId],
      );
      batch.delete(
        'meal_records',
        where: 'meal_id = ?',
        whereArgs: <Object?>[mealId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<LocalMealRecord>> listMealsForUser(String anonymousUserId) async {
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      'meal_records',
      where: 'anonymous_user_id = ?',
      whereArgs: <Object?>[anonymousUserId],
      orderBy: 'ended_at DESC',
    );
    return rows.map(_mealFromRow).toList();
  }

  Future<LocalMealRecord?> latestMealForUser(String anonymousUserId) async {
    final List<LocalMealRecord> meals = await listMealsForUser(anonymousUserId);
    if (meals.isEmpty) {
      return null;
    }
    return meals.first;
  }

  Future<int> todayMealCountForUser(String anonymousUserId) async {
    final List<LocalMealRecord> meals = await listMealsForUser(anonymousUserId);
    final DateTime now = DateTime.now();
    return meals.where((LocalMealRecord meal) {
      return meal.startedAt.year == now.year &&
          meal.startedAt.month == now.month &&
          meal.startedAt.day == now.day;
    }).length;
  }

  Future<MealReport> buildLatestMealReport(String anonymousUserId) async {
    final LocalMealRecord? meal = await latestMealForUser(anonymousUserId);
    if (meal == null) {
      return MealReport.placeholder();
    }

    final List<LocalReminderEvent> reminderEvents = await listReminderEventsForMeal(
      meal.mealId,
    );
    final String summaryText = meal.avgSpeed > 8
        ? '本地规则判断这餐夹菜频率偏高，建议把每口之间的停顿再拉开一点。'
        : '本地记录显示这餐夹菜节奏相对稳定，可以继续保持。';

    return MealReport(
      mealId: meal.mealId,
      durationSeconds: meal.endedAt.difference(meal.startedAt).inSeconds,
      intakeGrams: meal.intakeGrams,
      avgSpeed: meal.avgSpeed,
      peakSpeed: meal.peakSpeed,
      reminderCount: reminderEvents.length,
      summaryText: summaryText,
      aiSuggestion: null,
      reportSource: 'localDb',
    );
  }

  Future<TrendSummary> buildTrendSummary(String anonymousUserId) async {
    final List<LocalMealRecord> meals = await listMealsForUser(anonymousUserId);
    if (meals.isEmpty) {
      return TrendSummary.placeholder();
    }

    final List<LocalMealRecord> lastSevenMeals = meals.take(7).toList();
    final double avgSpeed = lastSevenMeals
            .map((LocalMealRecord meal) => meal.avgSpeed)
            .reduce((double a, double b) => a + b) /
        lastSevenMeals.length;
    final int fastMealCount = lastSevenMeals
        .where((LocalMealRecord meal) => meal.avgSpeed > 8)
        .length;
    final double oldest = lastSevenMeals.last.avgSpeed;
    final double newest = lastSevenMeals.first.avgSpeed;
    final double improvementRate = oldest <= 0
        ? 0
        : ((oldest - newest) / oldest).clamp(-1, 1).toDouble();

    return TrendSummary(
      days: 7,
      avgSpeed: avgSpeed,
      fastMealCount: fastMealCount,
      improvementRate: improvementRate,
      summaryText: fastMealCount > 0
          ? '最近样本里仍有夹菜频率偏高的餐次，建议继续依赖本地提醒拉住节奏。'
          : '最近样本整体比较平稳，本地夹菜节奏正在改善。',
      aiTrendInsight: null,
    );
  }

  @override
  Future<List<LocalMealRecord>> listMeals() async {
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      'meal_records',
      orderBy: 'ended_at DESC',
    );
    return rows.map(_mealFromRow).toList();
  }

  @override
  Future<List<LocalReminderEvent>> listReminderEventsForMeal(String mealId) async {
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      'reminder_events',
      where: 'meal_id = ?',
      whereArgs: <Object?>[mealId],
      orderBy: 'triggered_at ASC',
    );
    return rows.map(_reminderEventFromRow).toList();
  }

  @override
  Future<List<LocalWeightSample>> listSamplesForMeal(String mealId) async {
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      'weight_samples',
      where: 'meal_id = ?',
      whereArgs: <Object?>[mealId],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(_weightSampleFromRow).toList();
  }

  @override
  Future<void> saveMeal(LocalMealRecord meal) async {
    final Database db = await open();
    await db.insert(
      'meal_records',
      <String, Object?>{
        'meal_id': meal.mealId,
        'anonymous_user_id': meal.anonymousUserId,
        'started_at': meal.startedAt.toIso8601String(),
        'ended_at': meal.endedAt.toIso8601String(),
        'intake_grams': meal.intakeGrams,
        'avg_speed': meal.avgSpeed,
        'peak_speed': meal.peakSpeed,
        'reminder_count': meal.reminderCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveReminderEvent(LocalReminderEvent event) async {
    final Database db = await open();
    await db.insert(
      'reminder_events',
      <String, Object?>{
        'meal_id': event.mealId,
        'reminder_text': event.reminderText,
        'vibration_enabled': event.vibrationEnabled ? 1 : 0,
        'popup_enabled': event.popupEnabled ? 1 : 0,
        'voice_enabled': event.voiceEnabled ? 1 : 0,
        'triggered_at': event.triggeredAt.toIso8601String(),
      },
    );
  }

  @override
  Future<void> saveWeightSample(LocalWeightSample sample) async {
    final Database db = await open();
    await db.insert(
      'weight_samples',
      <String, Object?>{
        'meal_id': sample.mealId,
        'weight_gram': sample.weightGram,
        'recorded_at': sample.recordedAt.toIso8601String(),
      },
    );
  }

  DatabaseFactory _resolveDatabaseFactory() {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  LocalMealRecord _mealFromRow(Map<String, Object?> row) {
    return LocalMealRecord(
      mealId: row['meal_id']! as String,
      anonymousUserId: row['anonymous_user_id']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      endedAt: DateTime.parse(row['ended_at']! as String),
      intakeGrams: (row['intake_grams']! as num).toDouble(),
      avgSpeed: (row['avg_speed']! as num).toDouble(),
      peakSpeed: (row['peak_speed']! as num).toDouble(),
      reminderCount: row['reminder_count']! as int,
    );
  }

  LocalReminderEvent _reminderEventFromRow(Map<String, Object?> row) {
    return LocalReminderEvent(
      mealId: row['meal_id']! as String,
      reminderText: row['reminder_text']! as String,
      vibrationEnabled: (row['vibration_enabled'] as int? ?? 0) == 1,
      popupEnabled: (row['popup_enabled'] as int? ?? 0) == 1,
      voiceEnabled: row['voice_enabled']! as int == 1,
      triggeredAt: DateTime.parse(row['triggered_at']! as String),
    );
  }

  LocalWeightSample _weightSampleFromRow(Map<String, Object?> row) {
    return LocalWeightSample(
      mealId: row['meal_id']! as String,
      weightGram: (row['weight_gram']! as num).toDouble(),
      recordedAt: DateTime.parse(row['recorded_at']! as String),
    );
  }
}
