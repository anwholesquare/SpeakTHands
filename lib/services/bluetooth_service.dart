import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/hand_sensor_data.dart';

class BluetoothService extends ChangeNotifier {
  static const String deviceName = 'HandsOnSync-ESP32';
  static const String serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String txCharacteristicUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // Notify
  static const String rxCharacteristicUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // Write

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final StreamController<HandSensorData> _sensorDataController = StreamController<HandSensorData>.broadcast();
  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  final StreamController<List<BluetoothDevice>> _availableDevicesController = StreamController<List<BluetoothDevice>>.broadcast();

  // Public streams
  Stream<HandSensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<BluetoothDevice>> get availableDevicesStream => _availableDevicesController.stream;

  // Current state
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothDevice> _availableDevices = [];
  HandSensorData? _latestSensorData;
  bool _isScanning = false;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothConnectionState get connectionState => _connectionState;
  List<BluetoothDevice> get availableDevices => _availableDevices;
  HandSensorData? get latestSensorData => _latestSensorData;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;

  @override
  void dispose() {
    _disconnect();
    _sensorDataController.close();
    _connectionStateController.close();
    _availableDevicesController.close();
    super.dispose();
  }

  /// Initialize Bluetooth service and check permissions
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        debugPrint('Bluetooth not supported on this device');
        return false;
      }

      // Request permissions
      final permissions = await _requestPermissions();
      if (!permissions) {
        debugPrint('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is enabled
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        debugPrint('Bluetooth is turned off');
        return false;
      }

      debugPrint('Bluetooth service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing Bluetooth service: $e');
      return false;
    }
  }

  /// Request necessary Bluetooth permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Permission $permission not granted: $status');
        return false;
      }
    }

    return true;
  }

  /// Start scanning for ESP32 devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _availableDevices.clear();
      notifyListeners();

      // Start scanning
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final devices = <BluetoothDevice>[];
        
        for (final result in results) {
          // Filter for our ESP32 device or devices with the correct service
          if (result.device.platformName.contains(deviceName) ||
              result.advertisementData.serviceUuids.contains(serviceUuid)) {
            if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
              devices.add(result.device);
            }
          }
        }

        _availableDevices = devices;
        _availableDevicesController.add(_availableDevices);
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Auto-stop scanning after timeout
      Timer(timeout, () {
        stopScanning();
      });

    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning for devices
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevice != null) {
        await _disconnect();
      }

      _connectedDevice = device;
      _updateConnectionState(BluetoothConnectionState.connecting);

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));

      // Listen to connection state changes
      _connectionStateSubscription = device.connectionState.listen((state) {
        _updateConnectionState(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanup();
        }
      });

      // Discover services
      final services = await device.discoverServices();
      
      // Find our service and characteristics
      for (final service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toUpperCase();
            
            if (charUuid == txCharacteristicUuid.toUpperCase()) {
              _txCharacteristic = characteristic;
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              _characteristicSubscription = characteristic.lastValueStream.listen(_onDataReceived);
            } else if (charUuid == rxCharacteristicUuid.toUpperCase()) {
              _rxCharacteristic = characteristic;
            }
          }
          break;
        }
      }

      if (_txCharacteristic == null || _rxCharacteristic == null) {
        throw Exception('Required characteristics not found');
      }

      debugPrint('Successfully connected to ${device.platformName}');
      return true;

    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _cleanup();
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    await _disconnect();
  }

  Future<void> _disconnect() async {
    try {
      _characteristicSubscription?.cancel();
      _connectionStateSubscription?.cancel();
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
      _cleanup();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Send command to ESP32 (e.g., 'start_data', 'stop_data')
  Future<bool> sendCommand(String command) async {
    if (_rxCharacteristic == null || !isConnected) {
      debugPrint('Cannot send command: not connected');
      return false;
    }

    try {
      final data = utf8.encode(command);
      await _rxCharacteristic!.write(data);
      debugPrint('Sent command: $command');
      return true;
    } catch (e) {
      debugPrint('Error sending command: $e');
      return false;
    }
  }

  /// Handle incoming sensor data
  void _onDataReceived(List<int> data) {
    try {
      final dataString = utf8.decode(data);
      debugPrint('Received data: $dataString');
      
      // Parse the sensor data
      final sensorData = HandSensorData.fromBleData(dataString);
      _latestSensorData = sensorData;
      
      // Emit to stream
      _sensorDataController.add(sensorData);
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error parsing sensor data: $e');
    }
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(BluetoothConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
    notifyListeners();
  }

  /// Clean up resources
  void _cleanup() {
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _latestSensorData = null;
    _updateConnectionState(BluetoothConnectionState.disconnected);
  }

  /// Get connection status as human-readable string
  String get connectionStatusText {
    switch (_connectionState) {
      case BluetoothConnectionState.connected:
        return 'Connected';
      case BluetoothConnectionState.connecting:
        return 'Connecting...';
      case BluetoothConnectionState.disconnecting:
        return 'Disconnecting...';
      case BluetoothConnectionState.disconnected:
        return 'Disconnected';
    }
  }
}
