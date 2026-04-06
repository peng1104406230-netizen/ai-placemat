import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/ble/ble_gatt_debug_service.dart';
import '../core/ble/ble_scan_service.dart';
import '../core/engine/meal_engine.dart';
import '../core/engine/weight_processor.dart';
import '../core/parser/manufacturer_data_parser.dart';
import '../core/reminder/reminder_service.dart';
import '../core/storage/anonymous_user_store.dart';
import '../core/storage/local_db_contract.dart';
import '../models/anonymous_user.dart';
import '../models/device_debug_info.dart';
import '../models/gatt_debug_info.dart';
import '../models/meal_realtime_snapshot.dart';
import '../models/meal_report.dart';
import '../models/raw_ble_scan_result.dart';
import '../models/reminder_settings.dart';
import '../models/trend_summary.dart';
import 'app_state.dart';
import '../core/storage/local_db.dart';
import '../core/storage/settings_cache.dart';

class AppController extends ChangeNotifier {
  static const String _knownBhRemoteId = 'C1:00:00:08:9F:12';

  AppController({
    required AnonymousUserStore anonymousUserStore,
    required SettingsCache settingsCache,
    required LocalDb localDb,
    required BleScanService bleScanService,
    required BleGattDebugService bleGattDebugService,
    required ManufacturerDataParser parser,
    required WeightProcessor weightProcessor,
    required MealEngine mealEngine,
    required ReminderService reminderService,
  }) : _anonymousUserStore = anonymousUserStore,
       _settingsCache = settingsCache,
       _localDb = localDb,
       _bleScanService = bleScanService,
       _bleGattDebugService = bleGattDebugService,
       _parser = parser,
       _weightProcessor = weightProcessor,
       _mealEngine = mealEngine,
       _reminderService = reminderService;

  final AnonymousUserStore _anonymousUserStore;
  final SettingsCache _settingsCache;
  final LocalDb _localDb;
  final BleScanService _bleScanService;
  final BleGattDebugService _bleGattDebugService;
  final ManufacturerDataParser _parser;
  final WeightProcessor _weightProcessor;
  final MealEngine _mealEngine;
  final ReminderService _reminderService;
  StreamSubscription<BleScanSnapshot>? _bleSubscription;
  StreamSubscription<bool>? _bleScanningStateSubscription;
  StreamSubscription<GattDebugInfo>? _gattSubscription;
  String? _activeMealId;
  DateTime? _activeMealStartedAt;
  double _activeMealMaxWeight = 0;
  double _activeMealMinWeight = double.infinity;
  DateTime? _lastReminderAt;
  Future<void> _persistenceQueue = Future<void>.value();
  Future<void> _realtimeProcessingQueue = Future<void>.value();
  DateTime? _lastPersistedSampleAt;
  double? _lastPersistedSampleWeightGram;
  DateTime? _lastSummaryRefreshAt;
  double? _pendingRealtimeWeightGram;
  DateTime? _pendingRealtimeTimestamp;
  bool _isRealtimeProcessingScheduled = false;
  String _persistenceStatus = '本地记录后台写入已开启；写入会在后台串行执行，不阻塞实时页面。';
  String _realtimeProcessingStatus =
      '5 点平滑与 MealEngine 已恢复；当前在后台异步处理，不阻塞实时页面。';
  bool _latestReminderCanTrigger = false;
  String _latestReminderNote = '当前不满足提醒触发条件。';
  String _latestReminderDeliverySummary = '未选择提醒方式';
  int _pendingReminderPopupToken = 0;
  String? _pendingReminderPopupMessage;

  bool isInitialized = false;
  bool isSavingSettings = false;
  bool isBleScanning = false;
  String? errorMessage;
  late AppState _state;

  AppState get state => _state;
  String get persistenceStatus => _persistenceStatus;
  String get realtimeProcessingStatus => _realtimeProcessingStatus;
  bool get latestReminderCanTrigger => _latestReminderCanTrigger;
  String get latestReminderNote => _latestReminderNote;
  String get latestReminderDeliverySummary => _latestReminderDeliverySummary;
  int get pendingReminderPopupToken => _pendingReminderPopupToken;
  String? get pendingReminderPopupMessage => _pendingReminderPopupMessage;

  Future<void> initialize() async {
    try {
      final AnonymousUser anonymousUser = _anonymousUserStore.loadOrCreate();
      final ReminderSettings reminderSettings = _settingsCache.load();
      final ReminderPreview preview = _reminderService.preview(reminderSettings);
      _mealEngine.updateMaxPicksPerMinute(
        reminderSettings.maxPicksPerMinute,
      );
      _latestReminderCanTrigger = false;
      _latestReminderNote = preview.note;
      _latestReminderDeliverySummary = preview.deliverySummary;

      await _localDb.open();
      await _localDb.deleteLegacyDemoMealsForUser(
        anonymousUserId: anonymousUser.anonymousUserId,
      );

      final DeviceDebugInfo deviceDebugInfo = DeviceDebugInfo.empty();
      final MealReport mealReport = await _localDb.buildLatestMealReport(
        anonymousUser.anonymousUserId,
      );
      final TrendSummary trendSummary = await _localDb.buildTrendSummary(
        anonymousUser.anonymousUserId,
      );
      final int todayMealCount = await _localDb.todayMealCountForUser(
        anonymousUser.anonymousUserId,
      );

      _state = AppState(
        anonymousUser: anonymousUser,
        reminderSettings: reminderSettings,
        deviceDebugInfo: deviceDebugInfo,
        gattDebugInfo: GattDebugInfo.empty(),
        realtimeSnapshot: MealRealtimeSnapshot.initial(),
        mealReport: mealReport,
        trendSummary: trendSummary,
        todayMealCount: todayMealCount,
      );
      await _bleScanningStateSubscription?.cancel();
      _bleScanningStateSubscription = _bleScanService.scanStateStream.listen((
        bool isScanning,
      ) {
        if (isBleScanning == isScanning) {
          return;
        }

        isBleScanning = isScanning;
        final String statusNote = isScanning
            ? 'BLE 持续扫描中，实时页会直接消费重量广播。'
            : 'BLE 扫描当前未运行。进入实时页会自动重新拉起扫描。';
        _state = _state.copyWith(
          deviceDebugInfo: _state.deviceDebugInfo.copyWith(
            statusNote: statusNote,
          ),
        );
        notifyListeners();
      });
      await _gattSubscription?.cancel();
      _gattSubscription = _bleGattDebugService.debugInfoStream.listen(
        (GattDebugInfo gattDebugInfo) {
          _state = _state.copyWith(gattDebugInfo: gattDebugInfo);
          notifyListeners();
        },
      );
      isInitialized = true;
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      errorMessage = '前端初始化失败：$error';
      notifyListeners();
    }
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    isSavingSettings = true;
    notifyListeners();

    final ReminderSettings saved = _settingsCache.save(
      settings.copyWith(syncState: 'localOnly'),
    );
    _mealEngine.updateMaxPicksPerMinute(saved.maxPicksPerMinute);
    final ReminderPreview preview = _reminderService.preview(saved);
    _latestReminderCanTrigger = false;
    _latestReminderNote = preview.note;
    _latestReminderDeliverySummary = preview.deliverySummary;
    _state = _state.copyWith(reminderSettings: saved);

    isSavingSettings = false;
    notifyListeners();
  }

  Future<String> previewReminderVoiceText(String text) async {
    return _reminderService.previewVoice(text);
  }

  void markReminderPopupShown(int token) {
    if (_pendingReminderPopupToken != token) {
      return;
    }
    _pendingReminderPopupMessage = null;
  }

  Future<void> refreshLocalSummaries() async {
    final String anonymousUserId = _state.anonymousUser.anonymousUserId;
    final MealReport mealReport = await _localDb.buildLatestMealReport(
      anonymousUserId,
    );
    final TrendSummary trendSummary = await _localDb.buildTrendSummary(
      anonymousUserId,
    );
    final int todayMealCount = await _localDb.todayMealCountForUser(
      anonymousUserId,
    );
    _state = _state.copyWith(
      mealReport: mealReport,
      trendSummary: trendSummary,
      todayMealCount: todayMealCount,
    );
    notifyListeners();
  }

  Future<void> usePreviewBroadcast() async {
    final BleScanSnapshot bleSnapshot = _bleScanService.mockLatestBhBroadcast();
    _applyBleSnapshot(bleSnapshot);
  }

  Future<void> startBhBleScan() async {
    try {
      _ensureBleSubscription();
      if (_bleScanService.isScanningNow) {
        isBleScanning = true;
        _state = _state.copyWith(
          deviceDebugInfo: _state.deviceDebugInfo.copyWith(
            statusNote: 'BLE 已在持续扫描，当前直接复用现有重量流。',
          ),
        );
        notifyListeners();
        return;
      }

      final String status = await _bleScanService.startBhScan();
      isBleScanning = _bleScanService.isScanningNow;
      _state = _state.copyWith(
        deviceDebugInfo: _state.deviceDebugInfo.copyWith(statusNote: status),
      );
      notifyListeners();
    } catch (error) {
      _state = _state.copyWith(
        deviceDebugInfo: _state.deviceDebugInfo.copyWith(
          statusNote: '启动 BLE 扫描失败：$error',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> stopBhBleScan() async {
    await _bleScanService.stopScan();
    isBleScanning = false;
    _state = _state.copyWith(
      deviceDebugInfo: _state.deviceDebugInfo.copyWith(
        statusNote: 'BLE 扫描已停止。',
      ),
    );
    notifyListeners();
  }

  Future<void> ensureBhBleScanForRealtime() async {
    _ensureBleSubscription();
    if (_bleScanService.isScanningNow) {
      isBleScanning = true;
      notifyListeners();
      return;
    }

    await startBhBleScan();
  }

  Future<void> connectBhGatt() async {
    final RawBleScanResult? bhResult = _resolveBhTarget();
    if (bhResult == null) {
      _state = _state.copyWith(
        gattDebugInfo: _state.gattDebugInfo.copyWith(
          connectionState: 'idle',
          statusNote: '当前还没有可连接的 BH 扫描结果，请先开始扫描并确认 BH 出现。',
        ),
      );
      notifyListeners();
      return;
    }

    await _bleGattDebugService.connect(
      remoteId: bhResult.macAddress,
      deviceName: bhResult.deviceName,
    );
  }

  Future<void> retryConnectBhGatt() async {
    final RawBleScanResult? bhResult = _resolveBhTarget();
    if (bhResult == null) {
      _state = _state.copyWith(
        gattDebugInfo: _state.gattDebugInfo.copyWith(
          connectionState: 'idle',
          statusNote: '当前还没有可连接的 BH 扫描结果，请先开始扫描并确认 BH 出现。',
        ),
      );
      notifyListeners();
      return;
    }

    await _bleGattDebugService.connectWithRetry(
      remoteId: bhResult.macAddress,
      deviceName: bhResult.deviceName,
      maxAttempts: 3,
    );
  }

  Future<void> disconnectBhGatt() async {
    await _bleGattDebugService.disconnect();
  }

  Future<void> readGattCharacteristic(String key) async {
    await _bleGattDebugService.readCharacteristic(key);
  }

  Future<void> toggleGattSubscription(String key) async {
    await _bleGattDebugService.toggleNotify(key);
  }

  void recordCurrentBhSample() {
    final DeviceDebugInfo info = _state.deviceDebugInfo;
    if (!info.focusIsBhCandidate || info.receivedAt == null) {
      _state = _state.copyWith(
        deviceDebugInfo: info.copyWith(
          statusNote: '当前没有可记录的 BH 完整样本，请先开始扫描并等待 BH 出现。',
        ),
      );
      notifyListeners();
      return;
    }

    final RecordedBhSample sample = RecordedBhSample(
      sampleId: 'sample-${DateTime.now().microsecondsSinceEpoch}',
      savedAt: DateTime.now(),
      frame: RawBleScanResult(
        deviceName: info.deviceName,
        advertisedName: info.advertisedName,
        platformName: info.platformName,
        localName: info.localName,
        macAddress: info.macAddress,
        rssi: info.rssi,
        manufacturerDataRaw: info.rawHex,
        serviceDataRaw: info.serviceDataRaw,
        serviceUuidsRaw: info.serviceUuidsRaw,
        txPowerLevel: info.txPowerLevel,
        appearance: info.appearance,
        connectable: info.connectable,
        advFlagsRaw: info.advFlagsRaw,
        receivedAt: info.receivedAt!,
        looksLikeBhCandidate: info.focusIsBhCandidate,
      ),
    );

    final List<RecordedBhSample> recorded = <RecordedBhSample>[
      sample,
      ...info.recordedBhSamples,
    ];
    _state = _state.copyWith(
      deviceDebugInfo: info.copyWith(
        recordedBhSamples: recorded,
        statusNote: '已记录 1 条 BH 样本，当前共 ${recorded.length} 条。',
      ),
    );
    notifyListeners();
  }

  void _applyBleSnapshot(BleScanSnapshot bleSnapshot) {
    final ParsedWeightResult parsedWeight = bleSnapshot.focusIsBhCandidate
        ? _parser.parse(bleSnapshot.manufacturerData)
        : const ParsedWeightResult(
            parserStrategy: ManufacturerDataParser.strategyName,
            weightGram: null,
            confidence: 0,
            notes: '当前焦点设备不是 BH，已跳过重量解析。',
            readings: <ParserReading>[],
          );
    final double pipelineInputWeightGram = bleSnapshot.shouldFeedRealtimePipeline
        ? (parsedWeight.weightGram ?? 0)
        : 0;
    MealRealtimeSnapshot realtimeSnapshot = _state.realtimeSnapshot;
    realtimeSnapshot = realtimeSnapshot.copyWith(
      rawWeightGram: pipelineInputWeightGram,
      lastUpdatedAt: bleSnapshot.receivedAt,
      statusNote: bleSnapshot.shouldFeedRealtimePipeline
          ? '当前使用 BH 正式解析值作为重量输入。5 点平滑正在后台更新。'
          : '当前未收到 BH 重量广播，实时页已回落到空载输入。',
    );

    _state = _state.copyWith(
      deviceDebugInfo: DeviceDebugInfo(
        deviceName: bleSnapshot.deviceName,
        advertisedName: bleSnapshot.advertisedName,
        platformName: bleSnapshot.platformName,
        localName: bleSnapshot.localName,
        macAddress: bleSnapshot.macAddress,
        rssi: bleSnapshot.rssi,
        rawHex: bleSnapshot.rawHex,
        manufacturerData: bleSnapshot.manufacturerData,
        serviceDataRaw: bleSnapshot.serviceDataRaw,
        serviceUuidsRaw: bleSnapshot.serviceUuidsRaw,
        txPowerLevel: bleSnapshot.txPowerLevel,
        appearance: bleSnapshot.appearance,
        connectable: bleSnapshot.connectable,
        advFlagsRaw: bleSnapshot.advFlagsRaw,
        receivedAt: bleSnapshot.receivedAt,
        parsedWeightGram: parsedWeight.weightGram,
        weightSource: parsedWeight.notes,
        parserStrategy: parsedWeight.parserStrategy,
        parserReadings: parsedWeight.readings,
        recentScanResults: bleSnapshot.recentResults,
        recentBhFrames: bleSnapshot.recentBhFrames,
        recordedBhSamples: _state.deviceDebugInfo.recordedBhSamples,
        permissionDebugInfo: bleSnapshot.permissionDebugInfo,
        adapterStatus: bleSnapshot.adapterStatus,
        scanConfig: bleSnapshot.scanConfig,
        filterSummary: bleSnapshot.filterSummary,
        totalSeenDevices: bleSnapshot.totalSeenDevices,
        bhCandidateCount: bleSnapshot.bhCandidateCount,
        focusIsBhCandidate: bleSnapshot.focusIsBhCandidate,
        statusNote:
            '${parsedWeight.weightGram == null ? "" : "BH 当前解析重量 ${parsedWeight.weightGram!.toStringAsFixed(0)} g。 "}'
            '${parsedWeight.notes} 收包时间 ${bleSnapshot.receivedAt.toIso8601String()}',
      ),
      realtimeSnapshot: realtimeSnapshot,
    );
    notifyListeners();
    _scheduleRealtimeProcessing(
      weightGram: pipelineInputWeightGram,
      timestamp: bleSnapshot.receivedAt,
    );
  }

  void _scheduleRealtimeProcessing({
    required double weightGram,
    required DateTime timestamp,
  }) {
    _pendingRealtimeWeightGram = weightGram;
    _pendingRealtimeTimestamp = timestamp;
    if (_isRealtimeProcessingScheduled) {
      return;
    }

    _isRealtimeProcessingScheduled = true;
    _realtimeProcessingQueue = _realtimeProcessingQueue.then((_) async {
      while (_pendingRealtimeTimestamp != null) {
        final double queuedWeight = _pendingRealtimeWeightGram ?? 0;
        final DateTime queuedTimestamp = _pendingRealtimeTimestamp!;
        _pendingRealtimeWeightGram = null;
        _pendingRealtimeTimestamp = null;

        final StableWeightSample stableWeight =
            await Future<StableWeightSample>.microtask(
              () => _weightProcessor.process(queuedWeight),
            );
        MealRealtimeSnapshot processedSnapshot =
            await Future<MealRealtimeSnapshot>.microtask(
              () => _mealEngine.evaluate(stableWeight.grams),
            );
        final ReminderPreview reminderPreview = _reminderService.evaluate(
          _state.reminderSettings,
          processedSnapshot,
        );
        _latestReminderCanTrigger = reminderPreview.canTrigger;
        _latestReminderNote = reminderPreview.note;
        _latestReminderDeliverySummary = reminderPreview.deliverySummary;
        processedSnapshot = processedSnapshot.copyWith(
          rawWeightGram: queuedWeight,
          lastUpdatedAt: queuedTimestamp,
          statusNote:
              '${processedSnapshot.statusNote} '
              '${stableWeight.stabilityNote} ${reminderPreview.note}',
        );

        _realtimeProcessingStatus =
            '5 点平滑与 MealEngine 已恢复；后台按最新一帧串行处理，主显示已回到 MealEngine。';
        _state = _state.copyWith(realtimeSnapshot: processedSnapshot);
        notifyListeners();

        if (_shouldQueueRealtimePersistence(
          timestamp: queuedTimestamp,
          snapshot: processedSnapshot,
          reminderPreview: reminderPreview,
        )) {
          unawaited(
            _enqueuePersistRealtimeFlow(
              timestamp: queuedTimestamp,
              snapshot: processedSnapshot,
              reminderPreview: reminderPreview,
            ),
          );
        }
      }
      _isRealtimeProcessingScheduled = false;
    });
  }

  Future<void> _enqueuePersistRealtimeFlow({
    required DateTime timestamp,
    required MealRealtimeSnapshot snapshot,
    required ReminderPreview reminderPreview,
  }) {
    _persistenceQueue = _persistenceQueue.then((_) async {
      try {
        await _persistRealtimeFlow(
          timestamp: timestamp,
          snapshot: snapshot,
          reminderPreview: reminderPreview,
        );
      } catch (error) {
        _persistenceStatus = '本地记录后台写入失败：$error';
        notifyListeners();
      }
    });
    return _persistenceQueue;
  }

  Future<void> _persistRealtimeFlow({
    required DateTime timestamp,
    required MealRealtimeSnapshot snapshot,
    required ReminderPreview reminderPreview,
  }) async {
    final String anonymousUserId = _state.anonymousUser.anonymousUserId;
    final double currentWeight = snapshot.weightGram;
    final bool mealShouldBeActive = snapshot.status != 'idle';
    final bool shouldTriggerReminder =
        reminderPreview.canTrigger &&
        _activeMealId != null &&
        (_lastReminderAt == null ||
            timestamp.difference(_lastReminderAt!).inSeconds >=
                _state.reminderSettings.reminderFrequency);

    if (shouldTriggerReminder) {
      _lastReminderAt = timestamp;
      await _localDb.saveReminderEvent(
        LocalReminderEvent(
          mealId: _activeMealId!,
          reminderText: _state.reminderSettings.reminderText,
          vibrationEnabled: _state.reminderSettings.vibrationEnabled,
          popupEnabled: _state.reminderSettings.popupEnabled,
          voiceEnabled: _state.reminderSettings.voiceEnabled,
          triggeredAt: timestamp,
        ),
      );
      unawaited(_reminderService.executeNonVisual(reminderPreview));
      if (reminderPreview.shouldPopup) {
        _pendingReminderPopupToken += 1;
        _pendingReminderPopupMessage = reminderPreview.message;
        notifyListeners();
      }
    }

    if (mealShouldBeActive) {
      _activeMealId ??= 'meal-${timestamp.millisecondsSinceEpoch}';
      _activeMealStartedAt ??= timestamp;
      _activeMealMaxWeight = currentWeight > _activeMealMaxWeight
          ? currentWeight
          : _activeMealMaxWeight;
      _activeMealMinWeight = _activeMealMinWeight == double.infinity
          ? currentWeight
          : (currentWeight < _activeMealMinWeight
              ? currentWeight
              : _activeMealMinWeight);

      if (_shouldPersistWeightSample(currentWeight, timestamp)) {
        await _localDb.saveWeightSample(
          LocalWeightSample(
            mealId: _activeMealId!,
            weightGram: currentWeight,
            recordedAt: timestamp,
          ),
        );
      }

      final double intakeGrams = (_activeMealMaxWeight - _activeMealMinWeight)
          .clamp(0, double.infinity)
          .toDouble();
      await _localDb.saveMeal(
        LocalMealRecord(
          mealId: _activeMealId!,
          anonymousUserId: anonymousUserId,
          startedAt: _activeMealStartedAt!,
          endedAt: timestamp,
          intakeGrams: intakeGrams,
          avgSpeed: snapshot.avgSpeed,
          peakSpeed: snapshot.peakSpeed,
          reminderCount: snapshot.reminderCount,
        ),
      );
      await _refreshLocalSummariesIfNeeded();
      return;
    }

    if (_activeMealId != null) {
      final double intakeGrams = (_activeMealMaxWeight - _activeMealMinWeight)
          .clamp(0, double.infinity)
          .toDouble();
      await _localDb.saveMeal(
        LocalMealRecord(
          mealId: _activeMealId!,
          anonymousUserId: anonymousUserId,
          startedAt: _activeMealStartedAt!,
          endedAt: timestamp,
          intakeGrams: intakeGrams,
          avgSpeed: snapshot.avgSpeed,
          peakSpeed: snapshot.peakSpeed,
          reminderCount: snapshot.reminderCount,
        ),
      );
      await _refreshLocalSummariesIfNeeded(force: true);
      _activeMealId = null;
      _activeMealStartedAt = null;
      _activeMealMaxWeight = 0;
      _activeMealMinWeight = double.infinity;
      _lastReminderAt = null;
      _lastPersistedSampleAt = null;
      _lastPersistedSampleWeightGram = null;
    }
  }

  bool _shouldQueueRealtimePersistence({
    required DateTime timestamp,
    required MealRealtimeSnapshot snapshot,
    required ReminderPreview reminderPreview,
  }) {
    final double currentWeight = snapshot.weightGram;
    if (snapshot.status != 'idle') {
      final bool shouldPersistSample = _shouldPersistWeightSample(
        currentWeight,
        timestamp,
        commit: false,
      );
      final bool shouldPersistReminder =
          reminderPreview.canTrigger &&
          (_lastReminderAt == null ||
              timestamp.difference(_lastReminderAt!).inSeconds >=
                  _state.reminderSettings.reminderFrequency);
      return shouldPersistSample || shouldPersistReminder || _activeMealId == null;
    }
    return _activeMealId != null;
  }

  bool _shouldPersistWeightSample(
    double currentWeight,
    DateTime timestamp, {
    bool commit = true,
  }) {
    final DateTime? lastPersistedAt = _lastPersistedSampleAt;
    final double? lastPersistedWeight = _lastPersistedSampleWeightGram;
    final bool firstPersist =
        lastPersistedAt == null || lastPersistedWeight == null;
    final int elapsedMs = firstPersist
        ? 9999
        : timestamp.difference(lastPersistedAt).inMilliseconds;
    final double delta = firstPersist
        ? currentWeight
        : (currentWeight - lastPersistedWeight).abs();
    final bool shouldPersist = firstPersist || elapsedMs >= 300 || delta >= 1;
    if (shouldPersist && commit) {
      _lastPersistedSampleAt = timestamp;
      _lastPersistedSampleWeightGram = currentWeight;
    }
    return shouldPersist;
  }

  Future<void> _refreshLocalSummariesIfNeeded({bool force = false}) async {
    final DateTime now = DateTime.now();
    if (!force &&
        _lastSummaryRefreshAt != null &&
        now.difference(_lastSummaryRefreshAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    final String anonymousUserId = _state.anonymousUser.anonymousUserId;
    final MealReport mealReport = await _localDb.buildLatestMealReport(
      anonymousUserId,
    );
    final TrendSummary trendSummary = await _localDb.buildTrendSummary(
      anonymousUserId,
    );
    final int todayMealCount = await _localDb.todayMealCountForUser(
      anonymousUserId,
    );
    _lastSummaryRefreshAt = DateTime.now();
    _state = _state.copyWith(
      mealReport: mealReport,
      trendSummary: trendSummary,
      todayMealCount: todayMealCount,
    );
    notifyListeners();
  }

  RawBleScanResult? _resolveBhTarget() {
    final DeviceDebugInfo info = _state.deviceDebugInfo;
    if (info.focusIsBhCandidate && info.receivedAt != null) {
      return RawBleScanResult(
        deviceName: info.deviceName,
        advertisedName: info.advertisedName,
        platformName: info.platformName,
        localName: info.localName,
        macAddress: info.macAddress,
        rssi: info.rssi,
        manufacturerDataRaw: info.rawHex,
        serviceDataRaw: info.serviceDataRaw,
        serviceUuidsRaw: info.serviceUuidsRaw,
        txPowerLevel: info.txPowerLevel,
        appearance: info.appearance,
        connectable: info.connectable,
        advFlagsRaw: info.advFlagsRaw,
        receivedAt: info.receivedAt!,
        looksLikeBhCandidate: true,
      );
    }
    if (info.recentBhFrames.isNotEmpty) {
      return info.recentBhFrames.first;
    }
    return RawBleScanResult(
      deviceName: 'BH',
      advertisedName: 'BH',
      platformName: 'BH',
      localName: 'BH',
      macAddress: _knownBhRemoteId,
      rssi: 0,
      manufacturerDataRaw: '',
      serviceDataRaw: '',
      serviceUuidsRaw: '',
      txPowerLevel: null,
      appearance: null,
      connectable: null,
      advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
      receivedAt: DateTime.now(),
      looksLikeBhCandidate: true,
    );
  }

  void _ensureBleSubscription() {
    if (_bleSubscription != null) {
      return;
    }

    _bleSubscription = _bleScanService.snapshots.listen(
      _applyBleSnapshot,
      onError: (Object error) {
        _state = _state.copyWith(
          deviceDebugInfo: _state.deviceDebugInfo.copyWith(
            statusNote: 'BLE 扫描失败：$error',
          ),
        );
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    final StreamSubscription<BleScanSnapshot>? bleSubscription = _bleSubscription;
    final StreamSubscription<bool>? bleScanningStateSubscription =
        _bleScanningStateSubscription;
    final StreamSubscription<GattDebugInfo>? gattSubscription =
        _gattSubscription;
    if (bleSubscription != null) {
      unawaited(bleSubscription.cancel());
    }
    if (bleScanningStateSubscription != null) {
      unawaited(bleScanningStateSubscription.cancel());
    }
    if (gattSubscription != null) {
      unawaited(gattSubscription.cancel());
    }
    unawaited(_bleGattDebugService.disconnect());
    unawaited(_reminderService.dispose());
    super.dispose();
  }
}
