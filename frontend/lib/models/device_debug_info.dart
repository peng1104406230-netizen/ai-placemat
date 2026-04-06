import '../core/parser/manufacturer_data_parser.dart';
import 'raw_ble_scan_result.dart';

class DeviceDebugInfo {
  const DeviceDebugInfo({
    required this.deviceName,
    required this.advertisedName,
    required this.platformName,
    required this.localName,
    required this.macAddress,
    required this.rssi,
    required this.rawHex,
    required this.manufacturerData,
    required this.serviceDataRaw,
    required this.serviceUuidsRaw,
    required this.txPowerLevel,
    required this.appearance,
    required this.connectable,
    required this.advFlagsRaw,
    required this.receivedAt,
    required this.parsedWeightGram,
    required this.weightSource,
    required this.parserStrategy,
    required this.parserReadings,
    required this.recentScanResults,
    required this.recentBhFrames,
    required this.recordedBhSamples,
    required this.permissionDebugInfo,
    required this.adapterStatus,
    required this.scanConfig,
    required this.filterSummary,
    required this.totalSeenDevices,
    required this.bhCandidateCount,
    required this.focusIsBhCandidate,
    required this.statusNote,
  });

  final String deviceName;
  final String advertisedName;
  final String platformName;
  final String localName;
  final String macAddress;
  final int rssi;
  final String rawHex;
  final List<int> manufacturerData;
  final String serviceDataRaw;
  final String serviceUuidsRaw;
  final int? txPowerLevel;
  final int? appearance;
  final bool? connectable;
  final String advFlagsRaw;
  final DateTime? receivedAt;
  final double? parsedWeightGram;
  final String weightSource;
  final String parserStrategy;
  final List<ParserReading> parserReadings;
  final List<RawBleScanResult> recentScanResults;
  final List<RawBleScanResult> recentBhFrames;
  final List<RecordedBhSample> recordedBhSamples;
  final BlePermissionDebugInfo permissionDebugInfo;
  final String adapterStatus;
  final String scanConfig;
  final String filterSummary;
  final int totalSeenDevices;
  final int bhCandidateCount;
  final bool focusIsBhCandidate;
  final String statusNote;

  factory DeviceDebugInfo.empty() {
    return DeviceDebugInfo(
      deviceName: 'BH',
      advertisedName: '',
      platformName: '',
      localName: '',
      macAddress: '--',
      rssi: 0,
      rawHex: '',
      manufacturerData: <int>[],
      serviceDataRaw: '',
      serviceUuidsRaw: '',
      txPowerLevel: null,
      appearance: null,
      connectable: null,
      advFlagsRaw: 'not_exposed_by_flutter_blue_plus',
      receivedAt: null,
      parsedWeightGram: null,
      weightSource: '',
      parserStrategy: 'bhManufacturerData',
      parserReadings: <ParserReading>[],
      recentScanResults: <RawBleScanResult>[],
      recentBhFrames: <RawBleScanResult>[],
      recordedBhSamples: <RecordedBhSample>[],
      permissionDebugInfo: BlePermissionDebugInfo.empty(),
      adapterStatus: 'unknown',
      scanConfig: '未启动扫描',
      filterSummary: '当前未应用扫描过滤',
      totalSeenDevices: 0,
      bhCandidateCount: 0,
      focusIsBhCandidate: false,
      statusNote: '等待开始扫描 BLE 广播包。',
    );
  }

  DeviceDebugInfo copyWith({
    String? deviceName,
    String? advertisedName,
    String? platformName,
    String? localName,
    String? macAddress,
    int? rssi,
    String? rawHex,
    List<int>? manufacturerData,
    String? serviceDataRaw,
    String? serviceUuidsRaw,
    int? txPowerLevel,
    int? appearance,
    bool? connectable,
    String? advFlagsRaw,
    DateTime? receivedAt,
    double? parsedWeightGram,
    String? weightSource,
    String? parserStrategy,
    List<ParserReading>? parserReadings,
    List<RawBleScanResult>? recentScanResults,
    List<RawBleScanResult>? recentBhFrames,
    List<RecordedBhSample>? recordedBhSamples,
    BlePermissionDebugInfo? permissionDebugInfo,
    String? adapterStatus,
    String? scanConfig,
    String? filterSummary,
    int? totalSeenDevices,
    int? bhCandidateCount,
    bool? focusIsBhCandidate,
    String? statusNote,
  }) {
    return DeviceDebugInfo(
      deviceName: deviceName ?? this.deviceName,
      advertisedName: advertisedName ?? this.advertisedName,
      platformName: platformName ?? this.platformName,
      localName: localName ?? this.localName,
      macAddress: macAddress ?? this.macAddress,
      rssi: rssi ?? this.rssi,
      rawHex: rawHex ?? this.rawHex,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      serviceDataRaw: serviceDataRaw ?? this.serviceDataRaw,
      serviceUuidsRaw: serviceUuidsRaw ?? this.serviceUuidsRaw,
      txPowerLevel: txPowerLevel ?? this.txPowerLevel,
      appearance: appearance ?? this.appearance,
      connectable: connectable ?? this.connectable,
      advFlagsRaw: advFlagsRaw ?? this.advFlagsRaw,
      receivedAt: receivedAt ?? this.receivedAt,
      parsedWeightGram: parsedWeightGram ?? this.parsedWeightGram,
      weightSource: weightSource ?? this.weightSource,
      parserStrategy: parserStrategy ?? this.parserStrategy,
      parserReadings: parserReadings ?? this.parserReadings,
      recentScanResults: recentScanResults ?? this.recentScanResults,
      recentBhFrames: recentBhFrames ?? this.recentBhFrames,
      recordedBhSamples: recordedBhSamples ?? this.recordedBhSamples,
      permissionDebugInfo: permissionDebugInfo ?? this.permissionDebugInfo,
      adapterStatus: adapterStatus ?? this.adapterStatus,
      scanConfig: scanConfig ?? this.scanConfig,
      filterSummary: filterSummary ?? this.filterSummary,
      totalSeenDevices: totalSeenDevices ?? this.totalSeenDevices,
      bhCandidateCount: bhCandidateCount ?? this.bhCandidateCount,
      focusIsBhCandidate: focusIsBhCandidate ?? this.focusIsBhCandidate,
      statusNote: statusNote ?? this.statusNote,
    );
  }
}
