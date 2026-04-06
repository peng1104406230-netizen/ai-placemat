class GattConnectionLogEntry {
  const GattConnectionLogEntry({
    required this.attempt,
    required this.event,
    required this.message,
    required this.occurredAt,
  });

  final int attempt;
  final String event;
  final String message;
  final DateTime occurredAt;
}

class GattValueEvent {
  const GattValueEvent({
    required this.characteristicKey,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.source,
    required this.valueHex,
    required this.receivedAt,
    required this.valueChanged,
  });

  final String characteristicKey;
  final String serviceUuid;
  final String characteristicUuid;
  final String source;
  final String valueHex;
  final DateTime receivedAt;
  final bool valueChanged;
}

class GattCharacteristicDebugInfo {
  const GattCharacteristicDebugInfo({
    required this.key,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.instanceId,
    required this.propertiesLabel,
    required this.canRead,
    required this.canWrite,
    required this.canWriteWithoutResponse,
    required this.canNotify,
    required this.canIndicate,
    required this.isNotifying,
    required this.lastValueHex,
    required this.lastUpdatedAt,
    required this.updateCount,
    required this.distinctValueCount,
    required this.hasObservedValueChange,
  });

  final String key;
  final String serviceUuid;
  final String characteristicUuid;
  final int instanceId;
  final String propertiesLabel;
  final bool canRead;
  final bool canWrite;
  final bool canWriteWithoutResponse;
  final bool canNotify;
  final bool canIndicate;
  final bool isNotifying;
  final String lastValueHex;
  final DateTime? lastUpdatedAt;
  final int updateCount;
  final int distinctValueCount;
  final bool hasObservedValueChange;

  GattCharacteristicDebugInfo copyWith({
    String? key,
    String? serviceUuid,
    String? characteristicUuid,
    int? instanceId,
    String? propertiesLabel,
    bool? canRead,
    bool? canWrite,
    bool? canWriteWithoutResponse,
    bool? canNotify,
    bool? canIndicate,
    bool? isNotifying,
    String? lastValueHex,
    DateTime? lastUpdatedAt,
    int? updateCount,
    int? distinctValueCount,
    bool? hasObservedValueChange,
  }) {
    return GattCharacteristicDebugInfo(
      key: key ?? this.key,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      characteristicUuid: characteristicUuid ?? this.characteristicUuid,
      instanceId: instanceId ?? this.instanceId,
      propertiesLabel: propertiesLabel ?? this.propertiesLabel,
      canRead: canRead ?? this.canRead,
      canWrite: canWrite ?? this.canWrite,
      canWriteWithoutResponse:
          canWriteWithoutResponse ?? this.canWriteWithoutResponse,
      canNotify: canNotify ?? this.canNotify,
      canIndicate: canIndicate ?? this.canIndicate,
      isNotifying: isNotifying ?? this.isNotifying,
      lastValueHex: lastValueHex ?? this.lastValueHex,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      updateCount: updateCount ?? this.updateCount,
      distinctValueCount: distinctValueCount ?? this.distinctValueCount,
      hasObservedValueChange:
          hasObservedValueChange ?? this.hasObservedValueChange,
    );
  }
}

class GattServiceDebugInfo {
  const GattServiceDebugInfo({
    required this.serviceUuid,
    required this.isPrimary,
    required this.characteristics,
  });

  final String serviceUuid;
  final bool isPrimary;
  final List<GattCharacteristicDebugInfo> characteristics;

  GattServiceDebugInfo copyWith({
    String? serviceUuid,
    bool? isPrimary,
    List<GattCharacteristicDebugInfo>? characteristics,
  }) {
    return GattServiceDebugInfo(
      serviceUuid: serviceUuid ?? this.serviceUuid,
      isPrimary: isPrimary ?? this.isPrimary,
      characteristics: characteristics ?? this.characteristics,
    );
  }
}

class GattDebugInfo {
  const GattDebugInfo({
    required this.connectionState,
    required this.connectedDeviceName,
    required this.connectedRemoteId,
    required this.statusNote,
    required this.isRetrying,
    required this.services,
    required this.connectionLogs,
    required this.recentValueEvents,
    required this.connectedAt,
  });

  final String connectionState;
  final String connectedDeviceName;
  final String connectedRemoteId;
  final String statusNote;
  final bool isRetrying;
  final List<GattServiceDebugInfo> services;
  final List<GattConnectionLogEntry> connectionLogs;
  final List<GattValueEvent> recentValueEvents;
  final DateTime? connectedAt;

  factory GattDebugInfo.empty() {
    return const GattDebugInfo(
      connectionState: 'disconnected',
      connectedDeviceName: '',
      connectedRemoteId: '',
      statusNote: '尚未发起 GATT 连接。',
      isRetrying: false,
      services: <GattServiceDebugInfo>[],
      connectionLogs: <GattConnectionLogEntry>[],
      recentValueEvents: <GattValueEvent>[],
      connectedAt: null,
    );
  }

  GattDebugInfo copyWith({
    String? connectionState,
    String? connectedDeviceName,
    String? connectedRemoteId,
    String? statusNote,
    bool? isRetrying,
    List<GattServiceDebugInfo>? services,
    List<GattConnectionLogEntry>? connectionLogs,
    List<GattValueEvent>? recentValueEvents,
    DateTime? connectedAt,
  }) {
    return GattDebugInfo(
      connectionState: connectionState ?? this.connectionState,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedRemoteId: connectedRemoteId ?? this.connectedRemoteId,
      statusNote: statusNote ?? this.statusNote,
      isRetrying: isRetrying ?? this.isRetrying,
      services: services ?? this.services,
      connectionLogs: connectionLogs ?? this.connectionLogs,
      recentValueEvents: recentValueEvents ?? this.recentValueEvents,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}
