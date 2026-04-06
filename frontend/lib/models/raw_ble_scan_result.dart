class RawBleScanResult {
  const RawBleScanResult({
    required this.deviceName,
    required this.advertisedName,
    required this.platformName,
    required this.localName,
    required this.macAddress,
    required this.rssi,
    required this.manufacturerDataRaw,
    required this.serviceDataRaw,
    required this.serviceUuidsRaw,
    required this.txPowerLevel,
    required this.appearance,
    required this.connectable,
    required this.advFlagsRaw,
    required this.receivedAt,
    required this.looksLikeBhCandidate,
  });

  final String deviceName;
  final String advertisedName;
  final String platformName;
  final String localName;
  final String macAddress;
  final int rssi;
  final String manufacturerDataRaw;
  final String serviceDataRaw;
  final String serviceUuidsRaw;
  final int? txPowerLevel;
  final int? appearance;
  final bool? connectable;
  final String advFlagsRaw;
  final DateTime receivedAt;
  final bool looksLikeBhCandidate;
}

class RecordedBhSample {
  const RecordedBhSample({
    required this.sampleId,
    required this.savedAt,
    required this.frame,
  });

  final String sampleId;
  final DateTime savedAt;
  final RawBleScanResult frame;
}

class BlePermissionDebugInfo {
  const BlePermissionDebugInfo({
    required this.bluetoothScan,
    required this.bluetoothConnect,
    required this.locationWhenInUse,
    required this.requestTriggered,
    required this.checkedAt,
  });

  final String bluetoothScan;
  final String bluetoothConnect;
  final String locationWhenInUse;
  final bool requestTriggered;
  final DateTime? checkedAt;

  factory BlePermissionDebugInfo.empty() {
    return const BlePermissionDebugInfo(
      bluetoothScan: 'unknown',
      bluetoothConnect: 'unknown',
      locationWhenInUse: 'unknown',
      requestTriggered: false,
      checkedAt: null,
    );
  }

  String get summary {
    final String checkedLabel = checkedAt == null
        ? 'not checked yet'
        : checkedAt!.toIso8601String();
    return 'bluetoothScan=$bluetoothScan, '
        'bluetoothConnect=$bluetoothConnect, '
        'locationWhenInUse=$locationWhenInUse, '
        'requestTriggered=$requestTriggered, '
        'checkedAt=$checkedLabel';
  }
}
