import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../widgets/hand_visualization_widget.dart';
import '../services/bluetooth_service.dart';
import '../models/hand_sensor_data.dart';
import '../models/gesture_model.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';

class InferScreen extends StatefulWidget {
  const InferScreen({super.key});

  @override
  State<InferScreen> createState() => _InferScreenState();
}

class _InferScreenState extends State<InferScreen> with TickerProviderStateMixin {
  late ESP32BluetoothService _bluetoothService;
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();
  
  late AnimationController _connectionAnimController;
  late Animation<double> _connectionAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  HandSensorData? _currentSensorData;
  List<GestureModel> _savedGestures = [];
  GestureModel? _matchedGesture;
  bool _isRecording = false;
  final List<HandSensorData> _recordedGestures = [];
  
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _sensorDataSubscription;
  bool _isDisposed = false;
  bool _isInitializing = false;
  String? _lastSpokenGestureId; // Track last spoken gesture to avoid repeats
  DateTime? _lastSpeechTime; // Track timing to avoid rapid repeats
  
  @override
  void initState() {
    super.initState();
    _bluetoothService = ESP32BluetoothService();
    _initializeAnimations();
    _loadSavedGestures();
    _initializeTTS();
    _initializeBluetooth();
  }

  Future<void> _initializeTTS() async {
    try {
      await _ttsService.initialize();
      debugPrint('TTS service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS service: $e');
    }
  }

  void _initializeAnimations() {
    _connectionAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionAnimController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse animation for active fingers
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeBluetooth() async {
    if (_isInitializing || _isDisposed) return;
    _isInitializing = true;
    
    // Cancel existing subscriptions first
    _connectionStateSubscription?.cancel();
    _sensorDataSubscription?.cancel();
    
    final initialized = await _bluetoothService.initialize();
    if (initialized && !_isDisposed) {
      _connectionStateSubscription = _bluetoothService.connectionStateStream.listen((state) {
        if (mounted && !_isDisposed) {
          try {
            if (state == fbp.BluetoothConnectionState.connected) {
              _connectionAnimController.forward();
            } else {
              _connectionAnimController.reverse();
            }
          } catch (e) {
            // Animation controller might be disposed, ignore
            debugPrint('Animation controller error: $e');
          }
        }
      });

      _sensorDataSubscription = _bluetoothService.sensorDataStream.listen((data) {
        if (mounted && !_isDisposed) {
          setState(() {
            _currentSensorData = data;
            if (_isRecording) {
              _recordedGestures.add(data);
            }
          });
          _checkForGestureMatch(data);
        }
      });
    } else {
      // Check if permissions need manual setup
      final needsManualSetup = await _bluetoothService.needsManualPermissionSetup();
      if (needsManualSetup && mounted) {
        _showPermissionDialog();
      }
    }
    _isInitializing = false;
  }

  Future<void> _loadSavedGestures() async {
    try {
      final gestures = await _databaseService.getAllGestures();
      setState(() {
        _savedGestures = gestures;
      });
    } catch (e) {
      debugPrint('Error loading gestures: $e');
    }
  }

  void _checkForGestureMatch(HandSensorData data) {
    for (final gesture in _savedGestures) {
      // Simple pattern matching - you can enhance this logic
      if (gesture.sensorPattern == data.gesturePattern) {
        setState(() {
          _matchedGesture = gesture;
        });
        
        // Speak the matched gesture text through loudspeaker
        _speakMatchedGesture(gesture);
        break;
      }
    }
  }

  Future<void> _speakMatchedGesture(GestureModel gesture) async {
    try {
      final now = DateTime.now();
      
      // Avoid speaking the same gesture repeatedly within 3 seconds
      if (_lastSpokenGestureId == gesture.id && 
          _lastSpeechTime != null && 
          now.difference(_lastSpeechTime!).inSeconds < 3) {
        return;
      }

      // Get the text to speak (prioritize English, then first available)
      String? textToSpeak = gesture.textMappings['en'];
      if (textToSpeak == null || textToSpeak.isEmpty) {
        textToSpeak = gesture.textMappings.values.isNotEmpty 
            ? gesture.textMappings.values.first 
            : gesture.name;
      }

      if (textToSpeak.isNotEmpty) {
        debugPrint('Speaking gesture: ${gesture.name} -> "$textToSpeak"');
        
        // Stop any current speech first
        await _ttsService.stop();
        
        // Speak the gesture text
        final success = await _ttsService.speak(textToSpeak, languageCode: 'en-US');
        
        if (success) {
          _lastSpokenGestureId = gesture.id;
          _lastSpeechTime = now;
          debugPrint('Successfully spoke gesture: ${gesture.name}');
        } else {
          debugPrint('Failed to speak gesture: ${gesture.name}');
        }
      } else {
        debugPrint('No text to speak for gesture: ${gesture.name}');
      }
    } catch (e) {
      debugPrint('Error speaking matched gesture: $e');
    }
  }

  Future<void> _testTTS() async {
    try {
      debugPrint('Testing TTS with sample text');
      await _ttsService.stop(); // Stop any current speech
      
      final success = await _ttsService.speak(
        'Hello! This is a test of the text-to-speech system. Gesture recognition is working!',
        languageCode: 'en-US',
      );
      
      if (success) {
        debugPrint('TTS test successful');
      } else {
        debugPrint('TTS test failed');
      }
    } catch (e) {
      debugPrint('Error testing TTS: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectionStateSubscription?.cancel();
    _sensorDataSubscription?.cancel();
    _connectionAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildConnectionStatus(),
                      const SizedBox(height: 20),
                      _buildHandVisualization(),
                      const SizedBox(height: 20),
                      _buildControlButtons(),
                      // const SizedBox(height: 20),
                      // _buildSensorDataDisplay(),
                      const SizedBox(height: 20),
                      _buildMatchedGestureDisplay(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sensors,
              color: Colors.white,
              size: 20,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return GradientCard(
      child: Column(
        children: [
          // Device Status with Animation
          AnimatedBuilder(
            animation: _bluetoothService.isConnected ? _pulseAnimation : _connectionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bluetoothService.isConnected 
                    ? 1.0 + (_pulseAnimation.value * 0.05)
                    : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _bluetoothService.isConnected 
                          ? [AppTheme.successColor, Colors.green]
                          : [AppTheme.primaryColor, AppTheme.primaryVariant],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_bluetoothService.isConnected ? AppTheme.successColor : AppTheme.primaryColor)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: _bluetoothService.isConnected ? _pulseAnimation.value * 5 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _bluetoothService.isConnected ? Icons.sensors : Icons.bluetooth_searching,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Status Text
          Text(
            _bluetoothService.isConnected ? 'ESP32 Connected' : 'Searching for ESP32...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _bluetoothService.isConnected ? AppTheme.successColor : AppTheme.textPrimary,
                ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _bluetoothService.isConnected 
                ? 'Real-time hand tracking active'
                : 'Connect to start gesture recognition',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          
          if (_bluetoothService.connectedDevice != null) ...[
            const SizedBox(height: 16),
            
            // Device Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDeviceInfoRow('Device', _bluetoothService.connectedDevice!.platformName),
                  const SizedBox(height: 8),
                  _buildDeviceInfoRow('Protocol', 'Bluetooth Low Energy'),
                  const SizedBox(height: 8),
                  _buildDeviceInfoRow('Status', 'Streaming Data'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _bluetoothService.sendCommand('start_data'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _bluetoothService.sendCommand('stop_data'),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Check if permissions need manual setup first
                  final needsManualSetup = await _bluetoothService.needsManualPermissionSetup();
                  if (needsManualSetup) {
                    _showPermissionDialog();
                    return;
                  }
                  
                  _showDeviceSelectionDialog();
                },
                icon: const Icon(Icons.bluetooth),
                label: const Text('Connect to ESP32'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildHandVisualization() {
    return GradientCard(
      child: Column(
        children: [
          Text(
            'Real-time Hand Tracking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          
          // Enhanced finger visualization grid
          _buildFingerGrid(),
          
          const SizedBox(height: 20),
          
          // Hand visualization widget
          Center(
            child: HandVisualizationWidget(
              sensorData: _currentSensorData,
              size: 200,
              showLabels: false,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Overall hand status
          _buildHandStatus(),
        ],
      ),
    );
  }

  Widget _buildFingerGrid() {
    final fingers = [
      {'name': 'Thumb', 'code': 'T', 'value': _currentSensorData?.thumbKnuckle ?? false},
      {'name': 'Index', 'code': 'I', 'value': _currentSensorData?.indexKnuckle ?? false},
      {'name': 'Middle', 'code': 'M', 'value': _currentSensorData?.middleKnuckle ?? false},
      {'name': 'Ring', 'code': 'R', 'value': _currentSensorData?.ringKnuckle ?? false},
      {'name': 'Pinky', 'code': 'P', 'value': _currentSensorData?.pinkyKnuckle ?? false},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: fingers.map((finger) => _buildFingerCard(
        finger['name'] as String,
        finger['code'] as String,
        finger['value'] as bool,
      )).toList(),
    );
  }

  Widget _buildFingerCard(String name, String code, bool isActive) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseScale = isActive ? 1.0 + (_pulseAnimation.value * 0.05) : 1.0;
        final pulseOpacity = isActive ? 0.3 + (_pulseAnimation.value * 0.4) : 0.1;
        
        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: 65,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive 
                    ? [AppTheme.secondaryColor, AppTheme.primaryColor]
                    : [AppTheme.surfaceColor, AppTheme.cardColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppTheme.secondaryColor : Colors.black)
                      .withOpacity(pulseOpacity),
                  blurRadius: isActive ? 15 : 8,
                  spreadRadius: isActive ? _pulseAnimation.value * 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: TextStyle(
                        color: isActive ? AppTheme.secondaryColor : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandStatus() {
    if (_currentSensorData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.handBackLeft,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'No sensor data - Connect ESP32',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    final activeCount = _currentSensorData!.closedKnuckleCount;
    final totalCount = 5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Fingers',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              Text(
                '$activeCount / $totalCount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: activeCount / totalCount,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              activeCount > 0 ? AppTheme.secondaryColor : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pattern: ${_currentSensorData!.gesturePattern}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Recording and Save buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _recordedGestures.isNotEmpty ? _saveRecordedGesture : null,
                icon: const Icon(Icons.save),
                label: const Text('Save Gesture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Save Current Gesture button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _currentSensorData != null ? _saveCurrentGesture : null,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save Current Gesture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // TTS Test buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _testTTS,
                icon: const Icon(Icons.volume_up),
                label: const Text('Test TTS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _ttsService.stop(),
                icon: const Icon(Icons.volume_off),
                label: const Text('Stop TTS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorDataDisplay() {
    if (_currentSensorData == null) {
      return GradientCard(
        child: Column(
          children: [
            Icon(
              MdiIcons.handBackLeft,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No sensor data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            Text(
              'Connect to ESP32 to see real-time data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildSensorRow('Thumb (T)', _currentSensorData!.thumbKnuckle),
          _buildSensorRow('Index (I)', _currentSensorData!.indexKnuckle),
          _buildSensorRow('Middle (M)', _currentSensorData!.middleKnuckle),
          _buildSensorRow('Ring (R)', _currentSensorData!.ringKnuckle),
          _buildSensorRow('Pinky (P)', _currentSensorData!.pinkyKnuckle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pattern: ${_currentSensorData!.gesturePattern}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Active knuckles: ${_currentSensorData!.activeKnuckles.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Count: ${_currentSensorData!.closedKnuckleCount}/5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            width: 60,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                isActive ? 'CLOSED' : 'OPEN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedGestureDisplay() {
    if (_matchedGesture == null) {
      return GradientCard(
        child: Column(
          children: [
            Icon(
              MdiIcons.gestureSwipe,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No gesture matched',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            Text(
              'Make a gesture to see if it matches any saved ones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                MdiIcons.checkCircle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gesture Matched!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _matchedGesture!.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (_matchedGesture!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _matchedGesture!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Text output: ${_matchedGesture!.textMappings['en'] ?? 'No text mapping'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _speakMatchedGesture(_matchedGesture!),
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('Speak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordedGestures.clear();
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _saveCurrentGesture() async {
    if (_currentSensorData == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _GestureSaveDialog(),
    );

    if (result != null) {
      final gesture = GestureModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        description: result['description'] ?? '',
        sensorPattern: _currentSensorData!.gesturePattern,
        textMappings: {'en': result['text'] ?? ''},
        sensorData: SensorData(
          thumb: _currentSensorData!.thumbKnuckle ? 1 : 0,
          indexFinger: _currentSensorData!.indexKnuckle ? 1 : 0,
          middle: _currentSensorData!.middleKnuckle ? 1 : 0,
          ring: _currentSensorData!.ringKnuckle ? 1 : 0,
          pinky: _currentSensorData!.pinkyKnuckle ? 1 : 0,
          handRotation: 0, // Not available from current ESP32 setup
        ),
        workspaceId: 'default', // You might want to select workspace
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _databaseService.insertGesture(gesture);
        setState(() {
          _savedGestures.add(gesture);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current gesture "${gesture.name}" saved successfully!',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error saving gesture: $e',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveRecordedGesture() async {
    if (_recordedGestures.isEmpty) return;

    // For simplicity, use the last recorded gesture as the pattern
    final lastGesture = _recordedGestures.last;
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _GestureSaveDialog(),
    );

    if (result != null) {
      final gesture = GestureModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        description: result['description'] ?? '',
        sensorPattern: lastGesture.gesturePattern,
        textMappings: {'en': result['text'] ?? ''},
        sensorData: SensorData(
          thumb: lastGesture.thumbKnuckle ? 1 : 0,
          indexFinger: lastGesture.indexKnuckle ? 1 : 0,
          middle: lastGesture.middleKnuckle ? 1 : 0,
          ring: lastGesture.ringKnuckle ? 1 : 0,
          pinky: lastGesture.pinkyKnuckle ? 1 : 0,
          handRotation: 0, // Not available from current ESP32 setup
        ),
        workspaceId: 'default', // You might want to select workspace
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _databaseService.insertGesture(gesture);
        setState(() {
          _savedGestures.add(gesture);
          _recordedGestures.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recorded gesture "${gesture.name}" saved successfully!',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error saving recorded gesture: $e',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeviceSelectionDialog() async {
    await _bluetoothService.startScanning();
    
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.backgroundGradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bluetooth_searching,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Device',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Choose your ESP32 hand tracking device',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _bluetoothService.stopScanning();
                        await _bluetoothService.startScanning();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh scan',
                    ),
                  ],
                ),
              ),
              
              // Device List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: StreamBuilder<List<fbp.BluetoothDevice>>(
                    stream: _bluetoothService.availableDevicesStream,
                    builder: (context, snapshot) {
                      final devices = snapshot.data ?? [];
                      
                      if (devices.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bluetooth_searching,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Scanning for devices...',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Make sure your ESP32 is powered on and in pairing mode',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(),
                          ],
                        );
                      }

                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isESP32 = _bluetoothService.isESP32Device(device);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: isESP32 
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.successColor.withOpacity(0.1),
                                        AppTheme.secondaryColor.withOpacity(0.1),
                                      ],
                                    )
                                  : null,
                              color: isESP32 ? null : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isESP32 
                                  ? Border.all(
                                      color: AppTheme.successColor.withOpacity(0.3),
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _connectToDevice(device),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Device Icon
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isESP32 
                                                ? [AppTheme.successColor, AppTheme.secondaryColor]
                                                : [AppTheme.primaryColor, AppTheme.primaryVariant],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isESP32 ? AppTheme.successColor : AppTheme.primaryColor)
                                                  .withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isESP32 ? Icons.sensors : Icons.bluetooth,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Device Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    device.platformName.isNotEmpty 
                                                        ? device.platformName 
                                                        : 'Unknown Device',
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: isESP32 ? AppTheme.successColor : AppTheme.textPrimary,
                                                        ),
                                                  ),
                                                ),
                                                
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ID: ${device.remoteId.toString().substring(0, 8)}...',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                            ),
                                            
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Connect Button
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: isESP32 ? AppTheme.successColor : AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap a device to connect',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _bluetoothService.stopScanning();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    Navigator.of(context).pop(); // Close dialog
    await _bluetoothService.stopScanning();
    
    // Show elegant connecting indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Connecting to ${device.platformName.isNotEmpty ? device.platformName : "device"}...',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    
    final success = await _bluetoothService.connectToDevice(device);
    
    // Hide connecting indicator and show result
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  success 
                      ? 'Connected to ${device.platformName}!'
                      : 'Failed to connect to ${device.platformName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    final isIOS = Platform.isIOS;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isIOS ? Icons.bluetooth_disabled : Icons.warning_amber_rounded,
              color: isIOS ? Colors.blue : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(isIOS ? 'Bluetooth Setup Required' : 'Bluetooth Permissions Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIOS 
                ? 'To use hand tracking features, please ensure Bluetooth is enabled:'
                : 'Bluetooth permissions are permanently denied. To use hand tracking features, you need to:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (isIOS) ...[
              _buildPermissionStep('1', 'Open Control Center (swipe down from top-right)'),
              _buildPermissionStep('2', 'Tap and hold the Bluetooth icon'),
              _buildPermissionStep('3', 'Make sure Bluetooth is ON (blue)'),
              _buildPermissionStep('4', 'Return to SpeakTHands app'),
            ] else ...[
              _buildPermissionStep('1', 'Open device Settings'),
              _buildPermissionStep('2', 'Find "SpeakTHands" app'),
              _buildPermissionStep('3', 'Enable Bluetooth permissions'),
              _buildPermissionStep('4', 'Enable Location permissions (required for BLE scanning)'),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isIOS 
                        ? 'Bluetooth is needed to connect to your ESP32 device'
                        : 'These permissions are needed to connect to your ESP32 device',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (isIOS)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // On iOS, we can't directly open Bluetooth settings, but we can try again
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && !_isDisposed) {
                    _initializeBluetooth();
                  }
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _bluetoothService.openSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureSaveDialog extends StatefulWidget {
  @override
  State<_GestureSaveDialog> createState() => _GestureSaveDialogState();
}

class _GestureSaveDialogState extends State<_GestureSaveDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Gesture'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Gesture Name',
              hintText: 'e.g., Hello, Peace, OK',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Brief description of the gesture',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text Output',
              hintText: 'Text to speak when this gesture is detected',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _textController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'description': _descriptionController.text,
                'text': _textController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
