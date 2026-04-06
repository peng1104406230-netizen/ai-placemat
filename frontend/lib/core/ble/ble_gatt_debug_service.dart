import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/gatt_debug_info.dart';

class BleGattDebugService {
  BleGattDebugService();

  static const int _maxValueEvents = 40;
  static const int _maxConnectionLogs = 80;

  final StreamController<GattDebugInfo> _debugController =
      StreamController<GattDebugInfo>.broadcast();
  final Map<String, BluetoothCharacteristic> _characteristicsByKey =
      <String, BluetoothCharacteristic>{};
  final Map<String, StreamSubscription<List<int>>> _valueSubscriptions =
      <String, StreamSubscription<List<int>>>{};
  final Map<String, Set<String>> _distinctValuesByKey = <String, Set<String>>{};
  final Set<String> _pendingReadKeys = <String>{};

  GattDebugInfo _state = GattDebugInfo.empty();
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  Stream<GattDebugInfo> get debugInfoStream => _debugController.stream;

  GattDebugInfo get currentState => _state;

  Future<void> connect({
    required String remoteId,
    required String deviceName,
  }) async {
    await connectWithRetry(
      remoteId: remoteId,
      deviceName: deviceName,
      maxAttempts: 1,
    );
  }

  Future<void> connectWithRetry({
    required String remoteId,
    required String deviceName,
    int maxAttempts = 3,
  }) async {
    if (remoteId.isEmpty || remoteId == '--') {
      _appendConnectionLog(
        attempt: 0,
        event: 'connect skipped',
        message: '没有可用的 remoteId，无法发起 GATT 连接。',
      );
      _updateState(
        _state.copyWith(
          connectionState: 'error',
          statusNote: '没有可用的 remoteId，无法发起 GATT 连接。',
        ),
      );
      return;
    }

    _updateState(_state.copyWith(isRetrying: maxAttempts > 1));

    for (int attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final bool connected = await _connectOnce(
        remoteId: remoteId,
        deviceName: deviceName,
        attempt: attempt,
      );
      if (connected) {
        _updateState(_state.copyWith(isRetrying: false));
        return;
      }
      if (attempt < maxAttempts) {
        const Duration retryDelay = Duration(milliseconds: 1500);
        _appendConnectionLog(
          attempt: attempt,
          event: 'retry scheduled',
          message: '第 $attempt 次连接未成功，${retryDelay.inMilliseconds}ms 后开始下一次重试。',
        );
        _updateState(
          _state.copyWith(
            connectionState: 'retry_wait',
            statusNote:
                '第 $attempt 次连接未成功，准备在 ${retryDelay.inMilliseconds}ms 后重试。',
          ),
        );
        await Future<void>.delayed(retryDelay);
      }
    }

    _updateState(
      _state.copyWith(
        isRetrying: false,
        statusNote: '连续重试 $maxAttempts 次后仍未连接成功。',
      ),
    );
  }

  Future<bool> _connectOnce({
    required String remoteId,
    required String deviceName,
    required int attempt,
  }) async {
    if (_device != null && _device!.remoteId.str != remoteId) {
      await disconnect();
    }

    final BluetoothDevice device = BluetoothDevice.fromId(remoteId);
    _device = device;

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen(
      (BluetoothConnectionState state) {
        final String event = switch (state) {
          BluetoothConnectionState.connected => 'connected',
          BluetoothConnectionState.disconnected => 'disconnected',
          _ => 'connection state changed',
        };
        _appendConnectionLog(
          attempt: attempt,
          event: event,
          message: '第 $attempt 次连接状态变为 ${state.name}。',
        );
        _updateState(
          _state.copyWith(
            connectionState: state.name,
            statusNote: 'GATT 连接状态变为 ${state.name}。',
          ),
        );
        if (state == BluetoothConnectionState.disconnected) {
          unawaited(_clearCharacteristicRuntimeState(keepServices: true));
        }
      },
    );

    _appendConnectionLog(
      attempt: attempt,
      event: 'connect started',
      message: '开始第 $attempt 次连接 $deviceName ($remoteId)。',
    );
    _updateState(
      _state.copyWith(
        connectionState: 'connecting',
        connectedDeviceName: deviceName,
        connectedRemoteId: remoteId,
        statusNote: '正在进行第 $attempt 次连接：$deviceName ($remoteId)...',
      ),
    );

    try {
      if (device.isDisconnected) {
        await device.connect(
          timeout: const Duration(seconds: 15),
          mtu: null,
        );
      }

      _appendConnectionLog(
        attempt: attempt,
        event: 'discover services started',
        message: '第 $attempt 次连接成功，开始 discover services。',
      );
      _updateState(
        _state.copyWith(
          connectionState: 'discovering',
          connectedAt: DateTime.now(),
          statusNote: '连接成功，正在发现 services...',
        ),
      );

      final List<GattServiceDebugInfo> services = await _discoverServices(device);
      _appendConnectionLog(
        attempt: attempt,
        event: 'discover services finished',
        message: '第 $attempt 次 discover services 完成，共发现 ${services.length} 个 services。',
      );
      _updateState(
        _state.copyWith(
          connectionState: 'connected',
          connectedDeviceName:
              device.platformName.isNotEmpty ? device.platformName : deviceName,
          connectedRemoteId: remoteId,
          connectedAt: DateTime.now(),
          services: services,
          statusNote: '已连接并发现 ${services.length} 个 primary services。',
        ),
      );
      return true;
    } catch (error) {
      final String errorText = '$error';
      final bool isTimeout = error is TimeoutException ||
          errorText.toLowerCase().contains('timeout');
      _appendConnectionLog(
        attempt: attempt,
        event: isTimeout ? 'timeout' : 'connect failed',
        message: isTimeout
            ? '第 $attempt 次连接超时：$error'
            : '第 $attempt 次连接或发现失败：$error',
      );
      _updateState(
        _state.copyWith(
          connectionState: isTimeout ? 'timeout' : 'error',
          statusNote: isTimeout
              ? '第 $attempt 次 GATT 连接超时：$error'
              : '第 $attempt 次 GATT 连接或发现失败：$error',
        ),
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    final BluetoothDevice? device = _device;
    await _clearCharacteristicRuntimeState(keepServices: false);
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (device != null && device.isConnected) {
      try {
        await device.disconnect(queue: false);
      } catch (_) {}
    }

    _device = null;
    _updateState(
      GattDebugInfo.empty().copyWith(
        statusNote: 'GATT 连接已断开。',
        connectionLogs: _state.connectionLogs,
      ),
    );
  }

  Future<void> readCharacteristic(String key) async {
    final BluetoothCharacteristic? characteristic = _characteristicsByKey[key];
    if (characteristic == null) {
      _updateState(
        _state.copyWith(statusNote: '未找到对应 characteristic：$key'),
      );
      return;
    }

    try {
      _pendingReadKeys.add(key);
      _updateState(
        _state.copyWith(statusNote: '正在读取 characteristic ${characteristic.uuid.str}...'),
      );
      await characteristic.read();
    } catch (error) {
      _pendingReadKeys.remove(key);
      _updateState(
        _state.copyWith(statusNote: '读取 characteristic 失败：$error'),
      );
    }
  }

  Future<void> toggleNotify(String key) async {
    final BluetoothCharacteristic? characteristic = _characteristicsByKey[key];
    if (characteristic == null) {
      _updateState(
        _state.copyWith(statusNote: '未找到对应 characteristic：$key'),
      );
      return;
    }

    try {
      final bool nextValue = !characteristic.isNotifying;
      await characteristic.setNotifyValue(nextValue);
      _replaceCharacteristic(
        key,
        (GattCharacteristicDebugInfo info) => info.copyWith(
          isNotifying: nextValue,
        ),
      );
      _updateState(
        _state.copyWith(
          statusNote:
              '${nextValue ? '已订阅' : '已取消订阅'} characteristic ${characteristic.uuid.str}。',
        ),
      );
    } catch (error) {
      _updateState(
        _state.copyWith(statusNote: '订阅 characteristic 失败：$error'),
      );
    }
  }

  Future<List<GattServiceDebugInfo>> _discoverServices(
    BluetoothDevice device,
  ) async {
    await _clearCharacteristicRuntimeState(keepServices: true);
    final List<BluetoothService> services = await device.discoverServices();
    final List<GattServiceDebugInfo> output = <GattServiceDebugInfo>[];

    for (final BluetoothService service in services) {
      final List<GattCharacteristicDebugInfo> characteristics =
          <GattCharacteristicDebugInfo>[];

      for (final BluetoothCharacteristic characteristic in service.characteristics) {
        final String key = _characteristicKey(characteristic);
        _characteristicsByKey[key] = characteristic;
        _distinctValuesByKey[key] = <String>{};
        _listenToCharacteristic(characteristic, key);
        characteristics.add(_toCharacteristicInfo(characteristic, key));
      }

      output.add(
        GattServiceDebugInfo(
          serviceUuid: service.uuid.str,
          isPrimary: service.isPrimary,
          characteristics: characteristics,
        ),
      );
    }

    return output;
  }

  void _listenToCharacteristic(
    BluetoothCharacteristic characteristic,
    String key,
  ) {
    _valueSubscriptions[key]?.cancel();
    _valueSubscriptions[key] = characteristic.lastValueStream.listen(
      (List<int> value) {
        if (value.isEmpty) {
          return;
        }
        final String source;
        if (_pendingReadKeys.remove(key)) {
          source = 'read';
        } else if (characteristic.isNotifying) {
          source = 'notify/indicate';
        } else {
          source = 'stream';
        }
        _handleValueUpdate(
          key: key,
          characteristic: characteristic,
          value: value,
          source: source,
        );
      },
    );
  }

  void _handleValueUpdate({
    required String key,
    required BluetoothCharacteristic characteristic,
    required List<int> value,
    required String source,
  }) {
    final String valueHex = _toHex(value);
    final String previousValueHex = _findCharacteristic(key)?.lastValueHex ?? '';
    final bool valueChanged = previousValueHex.isNotEmpty && previousValueHex != valueHex;
    final Set<String> distinctValues = _distinctValuesByKey[key] ?? <String>{};
    distinctValues.add(valueHex);
    _distinctValuesByKey[key] = distinctValues;

    _replaceCharacteristic(
      key,
      (GattCharacteristicDebugInfo info) => info.copyWith(
        lastValueHex: valueHex,
        lastUpdatedAt: DateTime.now(),
        updateCount: info.updateCount + 1,
        distinctValueCount: distinctValues.length,
        hasObservedValueChange:
            info.hasObservedValueChange || distinctValues.length > 1,
        isNotifying: characteristic.isNotifying,
      ),
    );

    final List<GattValueEvent> nextEvents = <GattValueEvent>[
      GattValueEvent(
        characteristicKey: key,
        serviceUuid: characteristic.serviceUuid.str,
        characteristicUuid: characteristic.uuid.str,
        source: source,
        valueHex: valueHex,
        receivedAt: DateTime.now(),
        valueChanged: valueChanged,
      ),
      ..._state.recentValueEvents,
    ];
    if (nextEvents.length > _maxValueEvents) {
      nextEvents.removeRange(_maxValueEvents, nextEvents.length);
    }

    _updateState(
      _state.copyWith(
        recentValueEvents: nextEvents,
        statusNote:
            '收到 ${characteristic.uuid.str} 的 $source 原始字节：$valueHex',
      ),
    );
  }

  GattCharacteristicDebugInfo _toCharacteristicInfo(
    BluetoothCharacteristic characteristic,
    String key,
  ) {
    final CharacteristicProperties properties = characteristic.properties;
    return GattCharacteristicDebugInfo(
      key: key,
      serviceUuid: characteristic.serviceUuid.str,
      characteristicUuid: characteristic.uuid.str,
      instanceId: characteristic.instanceId,
      propertiesLabel: _propertiesLabel(properties),
      canRead: properties.read,
      canWrite: properties.write,
      canWriteWithoutResponse: properties.writeWithoutResponse,
      canNotify: properties.notify,
      canIndicate: properties.indicate,
      isNotifying: characteristic.isNotifying,
      lastValueHex: '',
      lastUpdatedAt: null,
      updateCount: 0,
      distinctValueCount: 0,
      hasObservedValueChange: false,
    );
  }

  String _propertiesLabel(CharacteristicProperties properties) {
    final List<String> labels = <String>[];
    if (properties.read) {
      labels.add('read');
    }
    if (properties.write) {
      labels.add('write');
    }
    if (properties.writeWithoutResponse) {
      labels.add('writeWithoutResponse');
    }
    if (properties.notify) {
      labels.add('notify');
    }
    if (properties.indicate) {
      labels.add('indicate');
    }
    if (properties.broadcast) {
      labels.add('broadcast');
    }
    return labels.isEmpty ? '(none)' : labels.join(', ');
  }

  Future<void> _clearCharacteristicRuntimeState({
    required bool keepServices,
  }) async {
    _pendingReadKeys.clear();
    for (final StreamSubscription<List<int>> subscription
        in _valueSubscriptions.values) {
      await subscription.cancel();
    }
    _valueSubscriptions.clear();
    _characteristicsByKey.clear();
    _distinctValuesByKey.clear();
    _state = _state.copyWith(
      services: keepServices ? _state.services : const <GattServiceDebugInfo>[],
      recentValueEvents: keepServices
          ? _state.recentValueEvents
          : const <GattValueEvent>[],
    );
  }

  void _replaceCharacteristic(
    String key,
    GattCharacteristicDebugInfo Function(GattCharacteristicDebugInfo) update,
  ) {
    final List<GattServiceDebugInfo> nextServices = _state.services
        .map((GattServiceDebugInfo service) {
          final List<GattCharacteristicDebugInfo> nextCharacteristics =
              service.characteristics
                  .map(
                    (GattCharacteristicDebugInfo characteristic) =>
                        characteristic.key == key
                        ? update(characteristic)
                        : characteristic,
                  )
                  .toList();
          return service.copyWith(characteristics: nextCharacteristics);
        })
        .toList();
    _state = _state.copyWith(services: nextServices);
  }

  GattCharacteristicDebugInfo? _findCharacteristic(String key) {
    for (final GattServiceDebugInfo service in _state.services) {
      for (final GattCharacteristicDebugInfo characteristic
          in service.characteristics) {
        if (characteristic.key == key) {
          return characteristic;
        }
      }
    }
    return null;
  }

  String _characteristicKey(BluetoothCharacteristic characteristic) {
    return '${characteristic.serviceUuid.str}/'
        '${characteristic.uuid.str}#${characteristic.instanceId}';
  }

  String _toHex(List<int> value) {
    return value
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void _updateState(GattDebugInfo nextState) {
    _state = nextState;
    _debugController.add(_state);
  }

  void _appendConnectionLog({
    required int attempt,
    required String event,
    required String message,
  }) {
    final List<GattConnectionLogEntry> nextLogs = <GattConnectionLogEntry>[
      GattConnectionLogEntry(
        attempt: attempt,
        event: event,
        message: message,
        occurredAt: DateTime.now(),
      ),
      ..._state.connectionLogs,
    ];
    if (nextLogs.length > _maxConnectionLogs) {
      nextLogs.removeRange(_maxConnectionLogs, nextLogs.length);
    }
    _state = _state.copyWith(connectionLogs: nextLogs);
    _debugController.add(_state);
  }
}
