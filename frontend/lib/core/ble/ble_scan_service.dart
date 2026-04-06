import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/raw_ble_scan_result.dart';

class BleScanSnapshot {
  const BleScanSnapshot({
    required this.deviceName,
    required this.advertisedName,
    required this.platformName,
    required this.localName,
    required this.macAddress,
    required this.rssi,
    required this.manufacturerData,
    required this.rawHex,
    required this.serviceDataRaw,
    required this.serviceUuidsRaw,
    required this.txPowerLevel,
    required this.appearance,
    required this.connectable,
    required this.advFlagsRaw,
    required this.receivedAt,
    required this.recentResults,
    required this.recentBhFrames,
    required this.permissionDebugInfo,
    required this.adapterStatus,
    required this.scanConfig,
    required this.filterSummary,
    required this.totalSeenDevices,
    required this.bhCandidateCount,
    required this.shouldFeedRealtimePipeline,
    required this.focusIsBhCandidate,
  });

  final String deviceName;
  final String advertisedName;
  final String platformName;
  final String localName;
  final String macAddress;
  final int rssi;
  final List<int> manufacturerData;
  final String rawHex;
  final String serviceDataRaw;
  final String serviceUuidsRaw;
  final int? txPowerLevel;
  final int? appearance;
  final bool? connectable;
  final String advFlagsRaw;
  final DateTime receivedAt;
  final List<RawBleScanResult> recentResults;
  final List<RawBleScanResult> recentBhFrames;
  final BlePermissionDebugInfo permissionDebugInfo;
  final String adapterStatus;
  final String scanConfig;
  final String filterSummary;
  final int totalSeenDevices;
  final int bhCandidateCount;
  final bool shouldFeedRealtimePipeline;
  final bool focusIsBhCandidate;
}

class BleScanService {
  const BleScanService();

  static const String targetDeviceName = 'BH';
  static const String _knownBhRemoteId = 'C1:00:00:08:9F:12';
  static const int _maxRecentResults = 20;
  static const EventChannel _nativeScanChannel = EventChannel('bh_ble_scan');
  static const String _scanConfigFlutterBluePlus =
      'source=flutterBluePlus; withNames=[]; withKeywords=[]; withServices=[]; '
      'androidUsesFineLocation=true; androidCheckLocationServices=true; '
      'androidScanMode=lowLatency; continuousUpdates=true; oneByOne=true; '
      'restartBeforeScan=true; restartDelayMs=200';
  static const String _scanConfigNativeAndroid =
      'source=nativeAndroidEventChannel; filters=[]; '
      'scanMode=LOW_LATENCY; reportDelayMs=0';

  static final StreamController<BleScanSnapshot> _snapshotController =
      StreamController<BleScanSnapshot>.broadcast();
  static final StreamController<bool> _scanStateController =
      StreamController<bool>.broadcast();
  static StreamSubscription<List<ScanResult>>? _scanSubscription;
  static StreamSubscription<dynamic>? _nativeScanSubscription;
  static final Map<String, RawBleScanResult> _recentResultsByDeviceId =
      <String, RawBleScanResult>{};
  static final List<RawBleScanResult> _recentBhFrames = <RawBleScanResult>[];
  static BlePermissionDebugInfo _permissionDebugInfo =
      BlePermissionDebugInfo.empty();
  static String _adapterStatus = 'unknown';
  static String _activeScanConfig = _scanConfigFlutterBluePlus;
  static const String _filterSummary =
      'UI 展示不过滤设备名；所有扫描结果都会显示。'
      ' 仅在内部将名称包含 BH 的设备标记为 BH 设备。';
  static bool _isScanningNow = false;

  Stream<BleScanSnapshot> get snapshots => _snapshotController.stream;
  Stream<bool> get scanStateStream => _scanStateController.stream;
  bool get isScanningNow => _isScanningNow;

  BleScanSnapshot mockLatestBhBroadcast() {
    return BleScanSnapshot(
      deviceName: targetDeviceName,
      advertisedName: targetDeviceName,
      platformName: targetDeviceName,
      localName: targetDeviceName,
      macAddress: '00:11:22:33:44:55',
      rssi: -49,
      manufacturerData: <int>[0x01, 0x02, 0x66, 0x00, 0x96, 0x00],
      rawHex: '010266009600',
      serviceDataRaw: '',
      serviceUuidsRaw: '',
      txPowerLevel: null,
      appearance: null,
      connectable: true,
      advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
      receivedAt: DateTime.now(),
      recentResults: <RawBleScanResult>[
        RawBleScanResult(
          deviceName: targetDeviceName,
          advertisedName: targetDeviceName,
          platformName: targetDeviceName,
          localName: targetDeviceName,
          macAddress: '00:11:22:33:44:55',
          rssi: -49,
          manufacturerDataRaw: '010266009600',
          serviceDataRaw: '',
          serviceUuidsRaw: '',
          txPowerLevel: null,
          appearance: null,
          connectable: true,
          advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
          receivedAt: DateTime.now(),
          looksLikeBhCandidate: true,
        ),
      ],
      recentBhFrames: <RawBleScanResult>[
        RawBleScanResult(
          deviceName: targetDeviceName,
          advertisedName: targetDeviceName,
          platformName: targetDeviceName,
          localName: targetDeviceName,
          macAddress: '00:11:22:33:44:55',
          rssi: -49,
          manufacturerDataRaw: '010266009600',
          serviceDataRaw: '',
          serviceUuidsRaw: '',
          txPowerLevel: null,
          appearance: null,
          connectable: true,
          advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
          receivedAt: DateTime.now(),
          looksLikeBhCandidate: true,
        ),
      ],
      permissionDebugInfo: _permissionDebugInfo,
      adapterStatus: _adapterStatus,
      scanConfig: _activeScanConfig,
      filterSummary: _filterSummary,
      totalSeenDevices: 1,
      bhCandidateCount: 1,
      shouldFeedRealtimePipeline: true,
      focusIsBhCandidate: true,
    );
  }

  String describeStatus() {
    return 'BLE service is ready for raw advertisement scanning.';
  }

  Future<String> startBhScan({
    Duration? timeout,
  }) async {
    final bool supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      return '当前设备不支持 BLE 扫描。';
    }

    final BluetoothAdapterState adapterState =
        await FlutterBluePlus.adapterState.first;
    _adapterStatus = adapterState.name;
    if (adapterState != BluetoothAdapterState.on) {
      return '蓝牙当前未开启，请先打开系统蓝牙。';
    }

    _permissionDebugInfo = await _ensurePermissions();
    _recentResultsByDeviceId.clear();
    _recentBhFrames.clear();

    await stopScan();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _snapshotController.add(
      BleScanSnapshot(
        deviceName: '--',
        advertisedName: '',
        platformName: '',
        localName: '',
        macAddress: '--',
        rssi: 0,
        manufacturerData: const <int>[],
        rawHex: '',
        serviceDataRaw: '',
        serviceUuidsRaw: '',
        txPowerLevel: null,
        appearance: null,
        connectable: null,
        advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
        receivedAt: DateTime.now(),
        recentResults: const <RawBleScanResult>[],
        recentBhFrames: const <RawBleScanResult>[],
        permissionDebugInfo: _permissionDebugInfo,
        adapterStatus: _adapterStatus,
        scanConfig: _activeScanConfig,
        filterSummary: _filterSummary,
        totalSeenDevices: 0,
        bhCandidateCount: 0,
        shouldFeedRealtimePipeline: false,
        focusIsBhCandidate: false,
      ),
    );

    if (_shouldUseNativeAndroidScan) {
      _activeScanConfig = _scanConfigNativeAndroid;
      _nativeScanSubscription = _nativeScanChannel.receiveBroadcastStream().listen(
        _handleNativeScanEvent,
        onError: (Object error, StackTrace stackTrace) {
          _setScanning(false);
          _snapshotController.addError(error, stackTrace);
        },
        onDone: () {
          _setScanning(false);
        },
      );
      return '正在使用 Android 原生 BLE EventChannel 持续扫描广播；实时页会直接消费这条原生重量流。';
    }

    _activeScanConfig = _scanConfigFlutterBluePlus;
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _handleScanResults,
      onError: (Object error, StackTrace stackTrace) {
        _setScanning(false);
        _snapshotController.addError(error, stackTrace);
      },
    );

    await FlutterBluePlus.startScan(
      timeout: timeout,
      continuousUpdates: true,
      continuousDivisor: 1,
      oneByOne: true,
      androidUsesFineLocation: true,
      androidCheckLocationServices: true,
      androidScanMode: AndroidScanMode.lowLatency,
    );
    _setScanning(true);
    return '正在持续扫描所有 BLE 广播包；调试页会显示最近 20 个原始设备，实时页也会直接消费这条重量流。';
  }

  Future<void> stopScan() async {
    await _nativeScanSubscription?.cancel();
    _nativeScanSubscription = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
    _setScanning(false);
  }

  bool get _shouldUseNativeAndroidScan =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _handleScanResults(List<ScanResult> results) {
    for (final ScanResult result in results) {
      final RawBleScanResult rawResult = _toRawResult(result);
      _recentResultsByDeviceId[rawResult.macAddress] = rawResult;
      _trackBhFrame(rawResult);
    }

    if (results.isEmpty) {
      return;
    }

    _emitSnapshotFromRecentResults();
  }

  void _trackBhFrame(RawBleScanResult rawResult) {
    if (!rawResult.looksLikeBhCandidate) {
      return;
    }

    if (_recentBhFrames.isNotEmpty) {
      final RawBleScanResult latest = _recentBhFrames.first;
      final bool isSameFrame =
          latest.receivedAt == rawResult.receivedAt &&
          latest.macAddress == rawResult.macAddress &&
          latest.rssi == rawResult.rssi &&
          latest.manufacturerDataRaw == rawResult.manufacturerDataRaw &&
          latest.serviceDataRaw == rawResult.serviceDataRaw &&
          latest.connectable == rawResult.connectable;
      if (isSameFrame) {
        return;
      }
    }

    _recentBhFrames.insert(0, rawResult);
    if (_recentBhFrames.length > _maxRecentResults) {
      _recentBhFrames.removeRange(_maxRecentResults, _recentBhFrames.length);
    }
  }

  Future<BlePermissionDebugInfo> _ensurePermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return BlePermissionDebugInfo(
        bluetoothScan: 'not_applicable',
        bluetoothConnect: 'not_applicable',
        locationWhenInUse: 'not_applicable',
        requestTriggered: false,
        checkedAt: DateTime.now(),
      );
    }

    final List<Permission> permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    bool requestTriggered = false;
    final Map<Permission, PermissionStatus> statuses =
        <Permission, PermissionStatus>{};

    for (final Permission permission in permissions) {
      PermissionStatus status = await permission.status;
      if (!status.isGranted) {
        requestTriggered = true;
        status = await permission.request();
      }
      statuses[permission] = status;
    }

    return BlePermissionDebugInfo(
      bluetoothScan:
          _permissionStatusLabel(statuses[Permission.bluetoothScan]),
      bluetoothConnect:
          _permissionStatusLabel(statuses[Permission.bluetoothConnect]),
      locationWhenInUse:
          _permissionStatusLabel(statuses[Permission.locationWhenInUse]),
      requestTriggered: requestTriggered,
      checkedAt: DateTime.now(),
    );
  }

  RawBleScanResult _toRawResult(ScanResult result) {
    final AdvertisementData advertisementData = result.advertisementData;
    _logManufacturerData(result, advertisementData);
    final String advertisedName = advertisementData.advName.trim();
    final String platformName = result.device.platformName.trim();
    final String resolvedName = advertisedName.isNotEmpty
        ? advertisedName
        : (platformName.isNotEmpty ? platformName : '(empty)');
    final String combinedName = '${advertisedName.toLowerCase()} ${platformName.toLowerCase()}';
    final String manufacturerDataRaw = advertisementData.manufacturerData.entries
        .map(
          (MapEntry<int, List<int>> entry) =>
              '0x${entry.key.toRadixString(16).padLeft(4, '0')}:${_toHex(entry.value)}',
        )
        .join(' | ');
    final String serviceDataRaw = advertisementData.serviceData.entries
        .map(
          (MapEntry<Guid, List<int>> entry) =>
              '${entry.key.str}:${_toHex(entry.value)}',
        )
        .join(' | ');
    final String serviceUuidsRaw = advertisementData.serviceUuids
        .map((Guid guid) => guid.str)
        .join(' | ');

    return RawBleScanResult(
      deviceName: resolvedName,
      advertisedName: advertisedName,
      platformName: platformName,
      localName: advertisedName,
      macAddress: result.device.remoteId.str,
      rssi: result.rssi,
      manufacturerDataRaw: manufacturerDataRaw,
      serviceDataRaw: serviceDataRaw,
      serviceUuidsRaw: serviceUuidsRaw,
      txPowerLevel: advertisementData.txPowerLevel,
      appearance: advertisementData.appearance,
      connectable: advertisementData.connectable,
      advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
      receivedAt: result.timeStamp,
      looksLikeBhCandidate:
          result.device.remoteId.str == _knownBhRemoteId ||
          combinedName.contains(targetDeviceName.toLowerCase()),
    );
  }

  void _handleNativeScanEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final Map<Object?, Object?> payload = event;
    final String type = payload['type']?.toString() ?? '';
    if (type == 'scan_state') {
      _setScanning(payload['isScanning'] == true);
      return;
    }
    if (type != 'scan_result') {
      return;
    }

    final String scanRecordRaw = payload['scanRecordRaw']?.toString() ?? '';
    final RawBleScanResult rawResult = _toRawResultFromNative(payload);
    _recentResultsByDeviceId[rawResult.macAddress] = rawResult;
    _trackBhFrame(rawResult);
    _logNativeManufacturerData(rawResult, scanRecordRaw);
    _emitSnapshotFromRecentResults();
  }

  RawBleScanResult _toRawResultFromNative(Map<Object?, Object?> payload) {
    final String advertisedName = payload['advertisedName']?.toString() ?? '';
    final String platformName = payload['platformName']?.toString() ?? '';
    final String localName = payload['localName']?.toString() ?? advertisedName;
    final String deviceName = payload['deviceName']?.toString() ?? '(empty)';
    final String macAddress = payload['remoteId']?.toString() ?? '--';
    final int rssi = (payload['rssi'] as num?)?.toInt() ?? 0;
    final int? txPowerLevel = (payload['txPowerLevel'] as num?)?.toInt();
    final int? appearance = (payload['appearance'] as num?)?.toInt();
    final bool? connectable = payload['connectable'] as bool?;
    final int receivedAtMs = (payload['receivedAtMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final String combinedName =
        '${advertisedName.toLowerCase()} ${platformName.toLowerCase()} ${deviceName.toLowerCase()}';

    return RawBleScanResult(
      deviceName: deviceName,
      advertisedName: advertisedName,
      platformName: platformName,
      localName: localName,
      macAddress: macAddress,
      rssi: rssi,
      manufacturerDataRaw: payload['manufacturerDataRaw']?.toString() ?? '',
      serviceDataRaw: payload['serviceDataRaw']?.toString() ?? '',
      serviceUuidsRaw: payload['serviceUuidsRaw']?.toString() ?? '',
      txPowerLevel: txPowerLevel,
      appearance: appearance,
      connectable: connectable,
      advFlagsRaw: payload['advFlagsRaw']?.toString() ?? 'unavailable',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMs),
      looksLikeBhCandidate:
          macAddress == _knownBhRemoteId ||
          combinedName.contains(targetDeviceName.toLowerCase()),
    );
  }

  void _logNativeManufacturerData(
    RawBleScanResult rawResult,
    String scanRecordRaw,
  ) {
    if (rawResult.manufacturerDataRaw.isEmpty) {
      return;
    }

    debugPrint(
      '[BLE mfData] '
      'name=${rawResult.deviceName} '
      'remoteId=${rawResult.macAddress} '
      'rssi=${rawResult.rssi} '
      'timestamp=${rawResult.receivedAt.toIso8601String()}',
    );

    final List<String> entries = rawResult.manufacturerDataRaw
        .split(' | ')
        .where((String item) => item.isNotEmpty)
        .toList();
    for (final String entry in entries) {
      final int separatorIndex = entry.indexOf(':');
      if (separatorIndex <= 0 || separatorIndex >= entry.length - 1) {
        continue;
      }

      final String companyId = entry.substring(0, separatorIndex);
      final List<int> bytes = _hexToBytes(entry.substring(separatorIndex + 1));
      debugPrint('companyId=$companyId');
      debugPrint(
        '字节: ${bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );
      if (rawResult.macAddress == _knownBhRemoteId && bytes.length >= 10) {
        debugPrint('BH数据时间(nowMs): ${DateTime.now().millisecondsSinceEpoch}');
        debugPrint(
          'BH广播时间(scanResultMs): ${rawResult.receivedAt.millisecondsSinceEpoch}',
        );
        final int parsedWeight = (bytes[8] << 8) | bytes[9];
        debugPrint('解析重量(bytes[8..9]) = ${parsedWeight}g');
      }
    }

    if (rawResult.macAddress != _knownBhRemoteId || scanRecordRaw.isEmpty) {
      return;
    }

    final List<int> scanRecordBytes = _hexToBytes(scanRecordRaw);
    debugPrint('scanRecordRaw: $scanRecordRaw');
    debugPrint(
      'scanRecord字节: ${scanRecordBytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
    if (scanRecordBytes.length >= 24) {
      final int nativeWeight =
          (scanRecordBytes[22] << 8) | scanRecordBytes[23];
      debugPrint(
        '原生扫描重量(bytes[22..23]) = $nativeWeight g '
        '(high=0x${scanRecordBytes[22].toRadixString(16).padLeft(2, '0')}, '
        'low=0x${scanRecordBytes[23].toRadixString(16).padLeft(2, '0')})',
      );
    } else {
      debugPrint(
        '原生扫描重量(bytes[22..23]) 无法解析，scanRecord 长度不足: ${scanRecordBytes.length}',
      );
    }
  }

  void _emitSnapshotFromRecentResults() {
    final List<RawBleScanResult> recentResults = _recentResultsByDeviceId.values
        .toList()
      ..sort(
        (RawBleScanResult a, RawBleScanResult b) =>
            b.receivedAt.compareTo(a.receivedAt),
      );
    if (recentResults.length > _maxRecentResults) {
      recentResults.removeRange(_maxRecentResults, recentResults.length);
    }

    final RawBleScanResult? focusResult = _pickFocusResult(recentResults);
    final List<int> manufacturerData = focusResult == null
        ? const <int>[]
        : _hexToBytes(focusResult.manufacturerDataRaw);

    _snapshotController.add(
      BleScanSnapshot(
        deviceName: focusResult?.deviceName ?? '--',
        advertisedName: focusResult?.advertisedName ?? '',
        platformName: focusResult?.platformName ?? '',
        localName: focusResult?.localName ?? '',
        macAddress: focusResult?.macAddress ?? '--',
        rssi: focusResult?.rssi ?? 0,
        manufacturerData: manufacturerData,
        rawHex: focusResult?.manufacturerDataRaw ?? '',
        serviceDataRaw: focusResult?.serviceDataRaw ?? '',
        serviceUuidsRaw: focusResult?.serviceUuidsRaw ?? '',
        txPowerLevel: focusResult?.txPowerLevel,
        appearance: focusResult?.appearance,
        connectable: focusResult?.connectable,
        advFlagsRaw: focusResult?.advFlagsRaw ?? 'not_exposed_by_flutter_blue_plus',
        receivedAt: focusResult?.receivedAt ?? DateTime.now(),
        recentResults: recentResults,
        recentBhFrames: List<RawBleScanResult>.unmodifiable(_recentBhFrames),
        permissionDebugInfo: _permissionDebugInfo,
        adapterStatus: _adapterStatus,
        scanConfig: _activeScanConfig,
        filterSummary: _filterSummary,
        totalSeenDevices: _recentResultsByDeviceId.length,
        bhCandidateCount: recentResults
            .where((RawBleScanResult item) => item.looksLikeBhCandidate)
            .length,
        shouldFeedRealtimePipeline:
            focusResult?.looksLikeBhCandidate == true && manufacturerData.isNotEmpty,
        focusIsBhCandidate: focusResult?.looksLikeBhCandidate == true,
      ),
    );
  }

  void _setScanning(bool value) {
    if (_isScanningNow == value) {
      return;
    }
    _isScanningNow = value;
    _scanStateController.add(value);
  }

  void _logManufacturerData(
    ScanResult result,
    AdvertisementData advertisementData,
  ) {
    if (advertisementData.manufacturerData.isEmpty) {
      return;
    }

    final String advertisedName = advertisementData.advName.trim();
    final String platformName = result.device.platformName.trim();
    final String resolvedName = advertisedName.isNotEmpty
        ? advertisedName
        : (platformName.isNotEmpty ? platformName : '(empty)');

    debugPrint(
      '[BLE mfData] '
      'name=$resolvedName '
      'remoteId=${result.device.remoteId.str} '
      'rssi=${result.rssi} '
      'timestamp=${result.timeStamp.toIso8601String()}',
    );

    final Map<int, List<int>> mfData = advertisementData.manufacturerData;
    mfData.forEach((int companyId, List<int> bytes) {
      debugPrint('companyId=0x${companyId.toRadixString(16)}');
      debugPrint(
        '字节: ${bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );
      if (result.device.remoteId.str == 'C1:00:00:08:9F:12' && bytes.length >= 10) {
        debugPrint('BH数据时间(nowMs): ${DateTime.now().millisecondsSinceEpoch}');
        debugPrint(
          'BH广播时间(scanResultMs): ${result.timeStamp.millisecondsSinceEpoch}',
        );
        final int parsedWeight = (bytes[8] << 8) | bytes[9];
        debugPrint('解析重量(bytes[8..9]) = ${parsedWeight}g');
      }
    });
  }

  RawBleScanResult? _pickFocusResult(List<RawBleScanResult> recentResults) {
    for (final RawBleScanResult result in recentResults) {
      if (result.macAddress == _knownBhRemoteId) {
        return result;
      }
    }
    for (final RawBleScanResult result in recentResults) {
      if (result.looksLikeBhCandidate) {
        return result;
      }
    }
    for (final RawBleScanResult result in recentResults) {
      if (result.manufacturerDataRaw.isNotEmpty) {
        return result;
      }
    }
    return recentResults.isEmpty ? null : recentResults.first;
  }

  List<int> _hexToBytes(String input) {
    if (input.isEmpty) {
      return const <int>[];
    }
    final String normalized = input.contains(':')
        ? input.split(':').last
        : input;
    final String hexOnly = normalized.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (hexOnly.length.isOdd) {
      return const <int>[];
    }

    final List<int> output = <int>[];
    for (int index = 0; index < hexOnly.length; index += 2) {
      output.add(int.parse(hexOnly.substring(index, index + 2), radix: 16));
    }
    return output;
  }

  String _permissionStatusLabel(PermissionStatus? status) {
    if (status == null) {
      return 'unknown';
    }
    if (status.isGranted) {
      return 'granted';
    }
    if (status.isDenied) {
      return 'denied';
    }
    if (status.isPermanentlyDenied) {
      return 'permanentlyDenied';
    }
    if (status.isRestricted) {
      return 'restricted';
    }
    if (status.isLimited) {
      return 'limited';
    }
    if (status.isProvisional) {
      return 'provisional';
    }
    return status.toString();
  }

  String _toHex(List<int> bytes) {
    return bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
