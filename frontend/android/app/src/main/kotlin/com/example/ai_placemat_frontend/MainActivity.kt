package com.example.ai_placemat_frontend

import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val channelName = "bh_ble_scan"
    private var eventSink: EventChannel.EventSink? = null
    private var scanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                        eventSink = sink
                        startNativeScan()
                    }

                    override fun onCancel(arguments: Any?) {
                        stopNativeScan()
                        eventSink = null
                    }
                },
            )
    }

    private fun startNativeScan() {
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter
        if (adapter == null || !adapter.isEnabled) {
            eventSink?.error("bluetooth_unavailable", "Bluetooth adapter is unavailable or disabled.", null)
            return
        }

        stopNativeScan()

        val bluetoothLeScanner = adapter.bluetoothLeScanner
        if (bluetoothLeScanner == null) {
            eventSink?.error("scanner_unavailable", "Bluetooth LE scanner is unavailable.", null)
            return
        }

        val settings =
            ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .setReportDelay(0)
                .build()

        val callback =
            object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult) {
                    emitScanResult(result)
                }

                override fun onBatchScanResults(results: MutableList<ScanResult>) {
                    results.forEach(::emitScanResult)
                }

                override fun onScanFailed(errorCode: Int) {
                    eventSink?.error("scan_failed", "Native BLE scan failed with errorCode=$errorCode", null)
                    emitScanState(false)
                }
            }

        scanner = bluetoothLeScanner
        scanCallback = callback
        bluetoothLeScanner.startScan(null, settings, callback)
        emitScanState(true)
    }

    private fun stopNativeScan() {
        val callback = scanCallback
        val bluetoothLeScanner = scanner
        if (callback != null && bluetoothLeScanner != null) {
            bluetoothLeScanner.stopScan(callback)
        }
        scanCallback = null
        scanner = null
        emitScanState(false)
    }

    private fun emitScanState(isScanning: Boolean) {
        eventSink?.success(
            mapOf(
                "type" to "scan_state",
                "isScanning" to isScanning,
            ),
        )
    }

    private fun emitScanResult(result: ScanResult) {
        val record = result.scanRecord
        val advertisedName = record?.deviceName.orEmpty()
        val platformName = result.device.name.orEmpty()
        val localName = advertisedName
        val remoteId = result.device.address.orEmpty()

        val manufacturerEntries = mutableListOf<String>()
        val manufacturerSpecificData = record?.manufacturerSpecificData
        if (manufacturerSpecificData != null) {
            for (index in 0 until manufacturerSpecificData.size()) {
                val companyId = manufacturerSpecificData.keyAt(index)
                val bytes = manufacturerSpecificData.valueAt(index)
                manufacturerEntries.add(
                    "0x${String.format(Locale.US, "%04x", companyId)}:${bytes.toHex()}",
                )
            }
        }

        val serviceUuidList =
            record?.serviceUuids?.map { parcelUuid -> parcelUuid.toString() } ?: emptyList()
        val serviceDataEntries = mutableListOf<String>()
        record?.serviceUuids?.forEach { parcelUuid ->
            val bytes = record.getServiceData(parcelUuid)
            if (bytes != null) {
                serviceDataEntries.add("${parcelUuid}:${bytes.toHex()}")
            }
        }

        val txPowerLevel = record?.txPowerLevel?.takeUnless { it == Int.MIN_VALUE }
        val advertiseFlags = record?.advertiseFlags ?: -1
        val advFlagsRaw =
            if (advertiseFlags >= 0) {
                "0x${advertiseFlags.toString(16)}"
            } else {
                "unavailable"
            }
        val connectable =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                result.isConnectable
            } else {
                null
            }

        eventSink?.success(
            mapOf(
                "type" to "scan_result",
                "deviceName" to if (advertisedName.isNotBlank()) advertisedName else if (platformName.isNotBlank()) platformName else "(empty)",
                "advertisedName" to advertisedName,
                "platformName" to platformName,
                "localName" to localName,
                "remoteId" to remoteId,
                "rssi" to result.rssi,
                "manufacturerDataRaw" to manufacturerEntries.joinToString(" | "),
                "serviceDataRaw" to serviceDataEntries.joinToString(" | "),
                "serviceUuidsRaw" to serviceUuidList.joinToString(" | "),
                "txPowerLevel" to txPowerLevel,
                "appearance" to null,
                "connectable" to connectable,
                "advFlagsRaw" to advFlagsRaw,
                "receivedAtMs" to System.currentTimeMillis(),
                "scanRecordRaw" to (record?.bytes?.toHex() ?: ""),
            ),
        )
    }

    private fun ByteArray.toHex(): String =
        joinToString(separator = "") { byte -> String.format(Locale.US, "%02x", byte.toInt() and 0xff) }
}
