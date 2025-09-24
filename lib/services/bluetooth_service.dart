import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/hand_sensor_data.dart';

class ESP32BluetoothService extends ChangeNotifier {
  static const String deviceName = 'HandsOnSync-ESP32';
  static const String serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String txCharacteristicUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // Notify
  static const String rxCharacteristicUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // Write

  // Singleton pattern to prevent multiple instances
  static ESP32BluetoothService? _instance;
  factory ESP32BluetoothService() {
    _instance ??= ESP32BluetoothService._internal();
    return _instance!;
  }
  ESP32BluetoothService._internal();

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
    _instance = null; // Reset singleton instance
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
      if (Platform.isIOS) {
        // On iOS, check adapter state with timeout
        try {
          final adapterState = await FlutterBluePlus.adapterState.first.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('iOS Bluetooth state check timed out, continuing anyway');
              return BluetoothAdapterState.on;
            },
          );
          
          debugPrint('iOS Bluetooth adapter state: $adapterState');
          // Continue initialization regardless of state on iOS
        } catch (e) {
          debugPrint('Error checking iOS Bluetooth state: $e, continuing anyway');
        }
      } else {
        // Android - check if Bluetooth is on
        try {
          final adapterState = await FlutterBluePlus.adapterState.first;
          if (adapterState != BluetoothAdapterState.on) {
            debugPrint('Android Bluetooth is not enabled. State: $adapterState');
            return false;
          }
        } catch (e) {
          debugPrint('Error checking Android Bluetooth state: $e');
          return false;
        }
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
    if (Platform.isIOS) {
      // On iOS, Bluetooth permissions are handled automatically by the system
      // when you try to use Bluetooth features. No explicit permission request needed.
      debugPrint('iOS detected - Bluetooth permissions handled by system');
      return true;
    }

    // Android permissions
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ];

    bool allGranted = true;
    final deniedPermissions = <Permission>[];

    for (final permission in permissions) {
      final status = await permission.status;
      
      if (status == PermissionStatus.granted) {
        continue;
      }
      
      if (status == PermissionStatus.permanentlyDenied) {
        debugPrint('Permission $permission is permanently denied');
        deniedPermissions.add(permission);
        allGranted = false;
        continue;
      }
      
      // Try to request permission
      final requestResult = await permission.request();
      if (requestResult != PermissionStatus.granted) {
        debugPrint('Permission $permission not granted: $requestResult');
        deniedPermissions.add(permission);
        allGranted = false;
      }
    }

    if (!allGranted && deniedPermissions.isNotEmpty) {
      debugPrint('Some permissions are denied. User needs to enable them manually.');
    }

    return allGranted;
  }

  /// Check if permissions need to be enabled manually in settings
  Future<bool> needsManualPermissionSetup() async {
    // FlutterBluePlus uses static methods, no instance needed
    
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return true; // Device doesn't support Bluetooth
      }
      
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        return true; // Bluetooth is off
      }

      // Check permissions on Android
      if (Platform.isAndroid) {
        final permissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.locationWhenInUse,
        ];

        for (final permission in permissions) {
          final status = await permission.status;
          if (status == PermissionStatus.permanentlyDenied) {
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
      return true;
    }
    
    return false;
  }

  /// Open app settings for manual permission configuration
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Start scanning for ESP32 devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _availableDevices.clear();
      notifyListeners();

      debugPrint('Starting BLE scan...');

      // Start scanning
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final devices = <BluetoothDevice>[];
        final esp32Devices = <BluetoothDevice>[];
        final otherDevices = <BluetoothDevice>[];
        
        for (final result in results) {
          debugPrint('Found device: ${result.device.platformName} (${result.device.remoteId})');
          debugPrint('Service UUIDs: ${result.advertisementData.serviceUuids}');
          
          // Add all devices with names (skip unnamed devices to reduce clutter)
          if (result.device.platformName.isNotEmpty) {
            if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
              // Check if it's an ESP32 or related device
              final isESP32 = isESP32Device(result.device) ||
                             result.advertisementData.serviceUuids.any((uuid) => 
                               uuid.toString().toUpperCase() == serviceUuid.toUpperCase());
              
              if (isESP32) {
                esp32Devices.add(result.device);
                debugPrint('Added ESP32 device: ${result.device.platformName}');
              } else {
                otherDevices.add(result.device);
                debugPrint('Added other device: ${result.device.platformName}');
              }
            }
          }
        }

        // Combine devices with ESP32 devices first
        devices.addAll(esp32Devices);
        devices.addAll(otherDevices);

        if (devices.length != _availableDevices.length) {
          _availableDevices = devices;
          _availableDevicesController.add(_availableDevices);
          notifyListeners();
          debugPrint('Updated available devices: ${devices.length} (${esp32Devices.length} ESP32, ${otherDevices.length} other)');
        }
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
      debugPrint('Stopped BLE scan');
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

  /// Check if a device is likely an ESP32 or hand tracking device
  bool isESP32Device(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    return name.contains(deviceName.toLowerCase()) ||
           name.contains('esp32') ||
           name.contains('nimble') ||
           name.contains('handsonsync');
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
