import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/parser/manufacturer_data_parser.dart';
import '../models/device_debug_info.dart';
import '../models/gatt_debug_info.dart';
import '../models/raw_ble_scan_result.dart';
import '../providers/app_controller.dart';

class DeviceDebugPage extends StatelessWidget {
  const DeviceDebugPage({required this.controller, super.key});

  static const String routeName = '/device-debug';

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final DeviceDebugInfo info = controller.state.deviceDebugInfo;
        final GattDebugInfo gatt = controller.state.gattDebugInfo;
        return Scaffold(
          appBar: AppBar(title: const Text('设备连接 / 蓝牙调试')),
          body: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                FilledButton(
                  onPressed: controller.isBleScanning
                      ? null
                      : controller.startBhBleScan,
                  child: Text(
                    controller.isBleScanning ? '扫描中...' : '开始真实扫描',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: controller.isBleScanning
                      ? controller.stopBhBleScan
                      : controller.usePreviewBroadcast,
                  child: Text(
                    controller.isBleScanning ? '停止扫描' : '载入本地预览广播数据',
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('权限状态'),
                    subtitle: Text(info.permissionDebugInfo.summary),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('蓝牙适配器状态'),
                    subtitle: Text(info.adapterStatus),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前扫描参数'),
                    subtitle: Text(info.scanConfig),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前过滤条件'),
                    subtitle: Text(info.filterSummary),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('扫描概览'),
                    subtitle: Text(
                      '已看到 ${info.totalSeenDevices} 个唯一设备，'
                      '其中 ${info.bhCandidateCount} 个名称看起来像 BH 设备。',
                    ),
                  ),
                ),
                _buildBhHighlightCard(context, info),
                const SizedBox(height: 12),
                const Text('当前设备信息快照'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Advertised Name / Local Name / Platform Name'),
                    subtitle: Text(
                      'advertisedName=${info.advertisedName.isEmpty ? '(empty)' : info.advertisedName}\n'
                      'localName=${info.localName.isEmpty ? '(empty)' : info.localName}\n'
                      'platformName=${info.platformName.isEmpty ? '(empty)' : info.platformName}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点设备名'),
                    subtitle: Text(info.deviceName),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 MAC'),
                    subtitle: Text(info.macAddress),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 RSSI'),
                    subtitle: Text('${info.rssi} dBm'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点时间戳'),
                    subtitle: Text(info.receivedAt?.toIso8601String() ?? '暂无'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 Raw Manufacturer Data'),
                    subtitle: Text(info.rawHex.isEmpty ? '暂无' : info.rawHex),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 Raw Service Data'),
                    subtitle: Text(
                      info.serviceDataRaw.isEmpty ? '暂无' : info.serviceDataRaw,
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 Service UUIDs'),
                    subtitle: Text(
                      info.serviceUuidsRaw.isEmpty ? '(empty)' : info.serviceUuidsRaw,
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 Tx Power / Appearance / Adv Flags'),
                    subtitle: Text(
                      'txPowerLevel=${info.txPowerLevel?.toString() ?? '(null)'}\n'
                      'appearance=${info.appearance?.toString() ?? '(null)'}\n'
                      'advFlags=${info.advFlagsRaw}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('当前焦点 Connectable'),
                    subtitle: Text(
                      info.connectable == null ? '未知' : '${info.connectable}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('BH 解析重量（bytes[8..9]）'),
                    subtitle: Text(
                      info.parsedWeightGram == null
                          ? '暂无'
                          : '${info.parsedWeightGram!.toStringAsFixed(0)} g\n${info.weightSource}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('解析策略'),
                    subtitle: Text(info.parserStrategy),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('解析说明'),
                    subtitle: Text(
                      info.weightSource.isEmpty ? '暂无' : info.weightSource,
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('状态说明'),
                    subtitle: Text(info.statusNote),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: info.focusIsBhCandidate
                            ? controller.recordCurrentBhSample
                            : null,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('记录当前样本'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('已记录样本列表'),
                const SizedBox(height: 8),
                if (info.recordedBhSamples.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无已记录样本'),
                      subtitle: Text('在 0g / 6g / 10g / 20g / 102g / 150g / 300g 时点击“记录当前样本”。'),
                    ),
                  ),
                ...info.recordedBhSamples
                    .map((RecordedBhSample sample) => _buildRecordedSampleCard(context, sample)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text('GATT 调试'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: controller.connectBhGatt,
                      icon: const Icon(Icons.bluetooth_connected_outlined),
                      label: const Text('连接 BH'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: gatt.isRetrying
                          ? null
                          : controller.retryConnectBhGatt,
                      icon: const Icon(Icons.refresh_outlined),
                      label: Text(
                        gatt.isRetrying ? '重试中...' : '重试连接 BH',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: gatt.connectionState == 'disconnected'
                          ? null
                          : controller.disconnectBhGatt,
                      icon: const Icon(Icons.bluetooth_disabled_outlined),
                      label: const Text('断开连接'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('GATT 连接状态'),
                    subtitle: Text(
                      'state=${gatt.connectionState}\n'
                      'isRetrying=${gatt.isRetrying}\n'
                      'device=${gatt.connectedDeviceName.isEmpty ? '(none)' : gatt.connectedDeviceName}\n'
                      'remoteId=${gatt.connectedRemoteId.isEmpty ? '(none)' : gatt.connectedRemoteId}\n'
                      'connectedAt=${gatt.connectedAt?.toIso8601String() ?? '(none)'}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('GATT 状态说明'),
                    subtitle: Text(gatt.statusNote),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('GATT 连接日志'),
                const SizedBox(height: 8),
                if (gatt.connectionLogs.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无 GATT 连接日志'),
                      subtitle: Text('点击“连接 BH”或“重试连接 BH”后，这里会显示 connect started / timeout / discover services 等事件。'),
                    ),
                  ),
                ...gatt.connectionLogs.take(24).map(
                  (GattConnectionLogEntry entry) =>
                      _buildGattConnectionLogCard(context, entry),
                ),
                const SizedBox(height: 8),
                const Text('已发现 Services / Characteristics'),
                const SizedBox(height: 8),
                if (gatt.services.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('尚未发现 GATT services'),
                      subtitle: Text('点击“连接 BH”后，这里会展示所有 service UUID、characteristic UUID 和属性。'),
                    ),
                  ),
                ...gatt.services.map(
                  (GattServiceDebugInfo service) =>
                      _buildGattServiceCard(context, service),
                ),
                const SizedBox(height: 12),
                const Text('最近 characteristic 原始字节事件'),
                const SizedBox(height: 8),
                if (gatt.recentValueEvents.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无 characteristic 字节事件'),
                      subtitle: Text('成功 read 或 subscribe notify / indicate 后，这里会实时显示原始 bytes（hex）。'),
                    ),
                  ),
                ...gatt.recentValueEvents.take(30).map(
                  (GattValueEvent event) =>
                      _buildGattValueEventCard(context, event),
                ),
                const SizedBox(height: 12),
                const Text('最近 BH 广播帧历史（最近 20 条，按时间倒序）'),
                const SizedBox(height: 8),
                if (info.recentBhFrames.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无 BH 广播帧'),
                      subtitle: Text('开始真实扫描后，这里会滚动显示最近看到的 BH 原始广播帧。'),
                    ),
                  ),
                ...info.recentBhFrames
                    .take(20)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (MapEntry<int, RawBleScanResult> entry) =>
                          _buildBhFrameCard(
                            context,
                            entry.value,
                            previousFrame:
                                entry.key + 1 < info.recentBhFrames.length
                                ? info.recentBhFrames[entry.key + 1]
                                : null,
                          ),
                    ),
                const SizedBox(height: 12),
                const Text('原始扫描结果列表（最近 20 个设备）'),
                const SizedBox(height: 8),
                if (info.recentScanResults.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无原始扫描结果'),
                      subtitle: Text('开始真实扫描后，这里会显示最近看到的设备。'),
                    ),
                  ),
                ...info.recentScanResults.take(20).map(_buildRawResultCard),
                const SizedBox(height: 12),
                const Text('重量解析字段'),
                const SizedBox(height: 8),
                if (info.parserReadings.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('暂无解析结果'),
                      subtitle: Text('请先开始真实扫描或载入预览广播数据。'),
                    ),
                  ),
                ...info.parserReadings.take(12).map(
                      (ParserReading reading) => Card(
                        child: ListTile(
                          title: Text(reading.label),
                          subtitle: Text(
                            'rawHex=${reading.rawHex} rawValue=${reading.rawValue} weight=${reading.weightGram.toStringAsFixed(1)} g',
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBhHighlightCard(
    BuildContext context,
    DeviceDebugInfo info,
  ) {
    final String manufacturerRaw = info.rawHex.isEmpty ? '暂无' : info.rawHex;
    final String bhPacketText = <String>[
      'name=${info.deviceName}',
      'remoteId=${info.macAddress}',
      'RSSI=${info.rssi} dBm',
      'manufacturer=$manufacturerRaw',
      'serviceUuids=${info.serviceUuidsRaw.isEmpty ? '(empty)' : info.serviceUuidsRaw}',
      'serviceData=${info.serviceDataRaw.isEmpty ? '(empty)' : info.serviceDataRaw}',
      'txPowerLevel=${info.txPowerLevel?.toString() ?? '(null)'}',
      'appearance=${info.appearance?.toString() ?? '(null)'}',
      'connectable=${info.connectable ?? 'unknown'}',
      'advFlags=${info.advFlagsRaw}',
      'timestamp=${info.receivedAt?.toIso8601String() ?? '暂无'}',
    ].join('\n');

    return Card(
      color: info.focusIsBhCandidate
          ? Colors.green.withValues(alpha: 0.12)
          : Colors.amber.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: Text(
                    info.focusIsBhCandidate ? '当前 BH 广播' : '当前焦点广播',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: manufacturerRaw == '暂无'
                      ? null
                      : () => _copyText(
                            context,
                            manufacturerRaw,
                            '已复制当前 BH manufacturer data',
                          ),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('复制 Manufacturer'),
                ),
                TextButton.icon(
                  onPressed: info.receivedAt == null
                      ? null
                      : () => _copyText(
                            context,
                            bhPacketText,
                            '已复制当前 BH 样本',
                          ),
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('复制整条样本'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              info.focusIsBhCandidate
                  ? '这块区域展示当前 BH 设备的完整 advertisement 快照；真正判断哪条帧会变，请看下面的 BH 广播帧历史。'
                  : '当前焦点还不确定是 BH，但复制能力已经就位。',
            ),
            const SizedBox(height: 12),
            SelectableText(
              bhPacketText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawResultCard(RawBleScanResult result) {
    return Card(
      color: result.looksLikeBhCandidate
          ? Colors.green.withValues(alpha: 0.08)
          : null,
      child: ListTile(
        title: Text(
          result.looksLikeBhCandidate
              ? '${result.deviceName} [BH]'
              : result.deviceName,
        ),
        subtitle: Text(
          'remoteId=${result.macAddress}\n'
          'RSSI=${result.rssi} dBm\n'
          'advertisedName=${result.advertisedName.isEmpty ? '(empty)' : result.advertisedName}\n'
          'localName=${result.localName.isEmpty ? '(empty)' : result.localName}\n'
          'platformName=${result.platformName.isEmpty ? '(empty)' : result.platformName}\n'
          'manufacturer=${result.manufacturerDataRaw.isEmpty ? '(empty)' : result.manufacturerDataRaw}\n'
          'serviceData=${result.serviceDataRaw.isEmpty ? '(empty)' : result.serviceDataRaw}\n'
          'serviceUuids=${result.serviceUuidsRaw.isEmpty ? '(empty)' : result.serviceUuidsRaw}\n'
          'txPowerLevel=${result.txPowerLevel?.toString() ?? '(null)'}\n'
          'appearance=${result.appearance?.toString() ?? '(null)'}\n'
          'connectable=${result.connectable?.toString() ?? 'unknown'}\n'
          'advFlags=${result.advFlagsRaw}\n'
          'timestamp=${result.receivedAt.toIso8601String()}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBhFrameCard(
    BuildContext context,
    RawBleScanResult result, {
    RawBleScanResult? previousFrame,
  }) {
    final bool manufacturerChanged = previousFrame == null
        ? false
        : previousFrame.macAddress == result.macAddress &&
            previousFrame.manufacturerDataRaw != result.manufacturerDataRaw;
    final bool serviceDataChanged = previousFrame == null
        ? false
        : previousFrame.macAddress == result.macAddress &&
            previousFrame.serviceDataRaw != result.serviceDataRaw;
    final String packetText =
        'advertisedName=${result.advertisedName.isEmpty ? '(empty)' : result.advertisedName}\n'
        'localName=${result.localName.isEmpty ? '(empty)' : result.localName}\n'
        'platformName=${result.platformName.isEmpty ? '(empty)' : result.platformName}\n'
        'timestamp=${result.receivedAt.toIso8601String()}\n'
        'remoteId=${result.macAddress}\n'
        'RSSI=${result.rssi} dBm\n'
        'manufacturer=${result.manufacturerDataRaw.isEmpty ? '(empty)' : result.manufacturerDataRaw}\n'
        'serviceData=${result.serviceDataRaw.isEmpty ? '(empty)' : result.serviceDataRaw}\n'
        'serviceUuids=${result.serviceUuidsRaw.isEmpty ? '(empty)' : result.serviceUuidsRaw}\n'
        'txPowerLevel=${result.txPowerLevel?.toString() ?? '(null)'}\n'
        'appearance=${result.appearance?.toString() ?? '(null)'}\n'
        'connectable=${result.connectable?.toString() ?? 'unknown'}\n'
        'advFlags=${result.advFlagsRaw}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildStatusChip(
                  context,
                  label: manufacturerChanged
                      ? 'manufacturer changed'
                      : 'manufacturer same/first',
                  emphasized: manufacturerChanged,
                ),
                _buildStatusChip(
                  context,
                  label: serviceDataChanged
                      ? 'serviceData changed'
                      : 'serviceData same/first',
                  emphasized: serviceDataChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: 280,
                  child: Text(
                    '${result.deviceName}  ${result.receivedAt.toIso8601String()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: '复制 manufacturer data',
                  onPressed: result.manufacturerDataRaw.isEmpty
                      ? null
                      : () => _copyText(
                            context,
                            result.manufacturerDataRaw,
                            '已复制 BH manufacturer data',
                          ),
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: '复制整条样本',
                  onPressed: () => _copyText(
                    context,
                    packetText,
                    '已复制 BH 样本',
                  ),
                  icon: const Icon(Icons.library_add_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              packetText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGattServiceCard(
    BuildContext context,
    GattServiceDebugInfo service,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SelectableText(
              'serviceUuid=${service.serviceUuid}\n'
              'isPrimary=${service.isPrimary}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 8),
            if (service.characteristics.isEmpty)
              const Text('该 service 下暂无 characteristics'),
            ...service.characteristics.map(
              (GattCharacteristicDebugInfo characteristic) =>
                  _buildGattCharacteristicCard(context, characteristic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGattCharacteristicCard(
    BuildContext context,
    GattCharacteristicDebugInfo characteristic,
  ) {
    final bool canSubscribe =
        characteristic.canNotify || characteristic.canIndicate;
    final bool emphasize = characteristic.hasObservedValueChange;
    final Color? cardColor = emphasize
        ? Colors.green.withValues(alpha: 0.12)
        : null;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildStatusChip(
                  context,
                  label: emphasize ? 'value changed' : 'no value change yet',
                  emphasized: emphasize,
                ),
                _buildStatusChip(
                  context,
                  label: characteristic.isNotifying
                      ? 'subscribed'
                      : 'not subscribed',
                  emphasized: characteristic.isNotifying,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              'characteristicUuid=${characteristic.characteristicUuid}\n'
              'instanceId=${characteristic.instanceId}\n'
              'serviceUuid=${characteristic.serviceUuid}\n'
              'properties=${characteristic.propertiesLabel}\n'
              'lastValue=${characteristic.lastValueHex.isEmpty ? '(empty)' : characteristic.lastValueHex}\n'
              'lastUpdatedAt=${characteristic.lastUpdatedAt?.toIso8601String() ?? '(none)'}\n'
              'updateCount=${characteristic.updateCount}\n'
              'distinctValueCount=${characteristic.distinctValueCount}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: characteristic.canRead
                      ? () => controller.readGattCharacteristic(
                            characteristic.key,
                          )
                      : null,
                  child: const Text('Read'),
                ),
                FilledButton(
                  onPressed: canSubscribe
                      ? () => controller.toggleGattSubscription(
                            characteristic.key,
                          )
                      : null,
                  child: Text(
                    characteristic.isNotifying
                        ? '取消订阅'
                        : '订阅 notify/indicate',
                  ),
                ),
                TextButton.icon(
                  onPressed: characteristic.lastValueHex.isEmpty
                      ? null
                      : () => _copyText(
                            context,
                            characteristic.lastValueHex,
                            '已复制 characteristic 原始 bytes',
                          ),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('复制 bytes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGattValueEventCard(
    BuildContext context,
    GattValueEvent event,
  ) {
    return Card(
      color: event.valueChanged
          ? Colors.green.withValues(alpha: 0.08)
          : null,
      child: ListTile(
        title: Text(
          '${event.characteristicUuid}  ${event.source}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
        subtitle: Text(
          'service=${event.serviceUuid}\n'
          'timestamp=${event.receivedAt.toIso8601String()}\n'
          'valueChanged=${event.valueChanged}\n'
          'valueHex=${event.valueHex}',
        ),
        trailing: IconButton(
          tooltip: '复制 bytes',
          onPressed: () => _copyText(
            context,
            event.valueHex,
            '已复制 GATT 原始 bytes',
          ),
          icon: const Icon(Icons.content_copy_outlined),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildGattConnectionLogCard(
    BuildContext context,
    GattConnectionLogEntry entry,
  ) {
    final bool emphasized = entry.event == 'connected' ||
        entry.event == 'discover services finished' ||
        entry.event == 'timeout';
    return Card(
      color: entry.event == 'timeout'
          ? Colors.orange.withValues(alpha: 0.12)
          : entry.event == 'connected'
              ? Colors.green.withValues(alpha: 0.08)
              : null,
      child: ListTile(
        title: Text(
          'attempt ${entry.attempt} · ${entry.event}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        subtitle: Text(
          'startedAt=${entry.occurredAt.toIso8601String()}\n'
          '${entry.message}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRecordedSampleCard(
    BuildContext context,
    RecordedBhSample sample,
  ) {
    final RawBleScanResult frame = sample.frame;
    final String sampleText =
        'savedAt=${sample.savedAt.toIso8601String()}\n'
        'advertisedName=${frame.advertisedName.isEmpty ? '(empty)' : frame.advertisedName}\n'
        'localName=${frame.localName.isEmpty ? '(empty)' : frame.localName}\n'
        'platformName=${frame.platformName.isEmpty ? '(empty)' : frame.platformName}\n'
        'timestamp=${frame.receivedAt.toIso8601String()}\n'
        'remoteId=${frame.macAddress}\n'
        'RSSI=${frame.rssi} dBm\n'
        'manufacturer=${frame.manufacturerDataRaw.isEmpty ? '(empty)' : frame.manufacturerDataRaw}\n'
        'serviceData=${frame.serviceDataRaw.isEmpty ? '(empty)' : frame.serviceDataRaw}\n'
        'serviceUuids=${frame.serviceUuidsRaw.isEmpty ? '(empty)' : frame.serviceUuidsRaw}\n'
        'txPowerLevel=${frame.txPowerLevel?.toString() ?? '(null)'}\n'
        'appearance=${frame.appearance?.toString() ?? '(null)'}\n'
        'connectable=${frame.connectable?.toString() ?? 'unknown'}\n'
        'advFlags=${frame.advFlagsRaw}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'sample saved at ${sample.savedAt.toIso8601String()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: '复制已记录样本',
                  onPressed: () => _copyText(
                    context,
                    sampleText,
                    '已复制已记录样本',
                  ),
                  icon: const Icon(Icons.content_copy_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              sampleText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required bool emphasized,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = emphasized
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final Color foreground = emphasized
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}
