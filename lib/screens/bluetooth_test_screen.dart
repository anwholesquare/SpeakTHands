import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothTestScreen extends StatefulWidget {
  const BluetoothTestScreen({super.key});

  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  // FlutterBluePlus doesn't use instance, it's static
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String statusMessage = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  Future<void> _checkBluetoothState() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      final adapterState = await FlutterBluePlus.adapterState.first;
      
      setState(() {
        statusMessage = 'Bluetooth Supported: $isSupported, State: $adapterState';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error checking Bluetooth: $e';
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        isScanning = true;
        scanResults.clear();
        statusMessage = 'Scanning...';
      });

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
          statusMessage = 'Found ${results.length} devices';
        });
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 10));
      await _stopScan();
    } catch (e) {
      setState(() {
        statusMessage = 'Scan error: $e';
        isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
        statusMessage = 'Scan completed. Found ${scanResults.length} devices';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Stop scan error: $e';
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(statusMessage),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _checkBluetoothState,
                          child: const Text('Check Bluetooth'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isScanning ? null : _startScan,
                          child: Text(isScanning ? 'Scanning...' : 'Start Scan'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isScanning ? _stopScan : null,
                          child: const Text('Stop Scan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discovered Devices:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: scanResults.isEmpty
                  ? const Center(
                      child: Text('No devices found. Try scanning.'),
                    )
                  : ListView.builder(
                      itemCount: scanResults.length,
                      itemBuilder: (context, index) {
                        final result = scanResults[index];
                        final device = result.device;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(
                              device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${device.remoteId}'),
                                Text('RSSI: ${result.rssi}'),
                                if (result.advertisementData.serviceUuids.isNotEmpty)
                                  Text('Services: ${result.advertisementData.serviceUuids.map((uuid) => uuid.toString().toUpperCase()).join(', ')}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _testConnect(device),
                              child: const Text('Test'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnect(BluetoothDevice device) async {
    try {
      setState(() {
        statusMessage = 'Connecting to ${device.platformName}...';
      });

      await device.connect(timeout: const Duration(seconds: 10));
      
      setState(() {
        statusMessage = 'Connected to ${device.platformName}! Discovering services...';
      });

      final services = await device.discoverServices();
      
      String serviceInfo = 'Services found:\n';
      for (final service in services) {
        serviceInfo += '- ${service.uuid}\n';
        for (final char in service.characteristics) {
          serviceInfo += '  - Char: ${char.uuid}\n';
        }
      }

      await device.disconnect();
      
      setState(() {
        statusMessage = 'Test completed for ${device.platformName}\n$serviceInfo';
      });

    } catch (e) {
      setState(() {
        statusMessage = 'Connection test failed: $e';
      });
    }
  }
}
