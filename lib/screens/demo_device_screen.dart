import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../themes/app_theme.dart';
import '../models/gesture_model.dart';
import '../widgets/gradient_card.dart';
import '../widgets/hand_animation_widget.dart';

class DemoDeviceScreen extends StatefulWidget {
  const DemoDeviceScreen({super.key});

  @override
  State<DemoDeviceScreen> createState() => _DemoDeviceScreenState();
}

class _DemoDeviceScreenState extends State<DemoDeviceScreen>
    with TickerProviderStateMixin {
  late AnimationController _connectingController;
  late AnimationController _pulseController;
  
  bool _isConnected = false;
  bool _isCalibrating = false;
  int _currentFingerIndex = 0;
  
  final List<FingerType> _calibrationOrder = [
    FingerType.thumb,
    FingerType.indexFinger,
    FingerType.middle,
    FingerType.ring,
    FingerType.pinky,
  ];

  @override
  void initState() {
    super.initState();
    
    _connectingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _simulateConnection();
  }

  void _simulateConnection() async {
    _connectingController.repeat();
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isConnected = true;
      });
      _connectingController.stop();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _connectingController.dispose();
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
              _buildAppBar(),
              Expanded(
                child: _isCalibrating
                    ? _buildCalibrationView()
                    : _buildDeviceView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Device',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _isCalibrating ? 'Finger Calibration' : 'ESP32 Simulator',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // Device Status Card
              GradientCard(
                child: Column(
                  children: [
                    // Device Icon with Animation
                    AnimatedBuilder(
                      animation: _isConnected ? _pulseController : _connectingController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isConnected 
                              ? 1.0 + (_pulseController.value * 0.1)
                              : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isConnected 
                                    ? [AppTheme.successColor, AppTheme.secondaryColor]
                                    : [AppTheme.primaryColor, AppTheme.primaryVariant],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isConnected ? AppTheme.successColor : AppTheme.primaryColor)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: _isConnected ? _pulseController.value * 5 : 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isConnected ? Icons.sensors : Icons.bluetooth_searching,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Status Text
                    Text(
                      _isConnected ? 'ESP32 Connected' : 'Connecting to ESP32...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isConnected ? AppTheme.successColor : AppTheme.textPrimary,
                          ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _isConnected 
                          ? 'Demo device ready for calibration'
                          : 'Simulating Bluetooth connection...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (_isConnected) ...[
                      const SizedBox(height: 24),
                      
                      // Device Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Device', 'ESP32 DevKit V1'),
                            const SizedBox(height: 8),
                            _buildInfoRow('Sensors', '5x Flex Sensor 2.2"'),
                            const SizedBox(height: 8),
                            _buildInfoRow('IMU', 'MPU6050 (6-axis)'),
                            const SizedBox(height: 8),
                            _buildInfoRow('Connection', 'Bluetooth Classic'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_isConnected) ...[
                // Calibration Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCalibrating = true;
                        _currentFingerIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Start Finger Calibration'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Quick Test Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showQuickTestDialog();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Quick Sensor Test'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationView() {
    final currentFinger = _calibrationOrder[_currentFingerIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Progress Indicator
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Text(
                  'Finger ${_currentFingerIndex + 1} of ${_calibrationOrder.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentFingerIndex + 1) / _calibrationOrder.length,
                  backgroundColor: AppTheme.dividerColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                ),
              ],
            ),
          ),
          
          // Hand Animation
          HandAnimationWidget(
            highlightedFinger: currentFinger,
            animationDuration: const Duration(milliseconds: 1500),
          ),
          
          const SizedBox(height: 30),
          
          // Instruction Card
          GradientCard(
            child: Column(
              children: [
                Text(
                  'Calibrate ${currentFinger.displayName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Move your ${currentFinger.displayName.toLowerCase()} finger slowly from fully extended to fully bent. The sensor will capture the range of motion.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Simulated sensor reading
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sensor Reading',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currentFinger.shortCode}: 45°',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Range: 0° - 120°',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextFinger,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentFingerIndex == _calibrationOrder.length - 1
                          ? 'Complete Calibration'
                          : 'Done - Next Finger',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Skip/Cancel Button
          TextButton(
            onPressed: () {
              setState(() {
                _isCalibrating = false;
                _currentFingerIndex = 0;
              });
            },
            child: const Text('Cancel Calibration'),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  void _nextFinger() {
    if (_currentFingerIndex < _calibrationOrder.length - 1) {
      setState(() {
        _currentFingerIndex++;
      });
    } else {
      // Calibration complete
      _showCalibrationCompleteDialog();
    }
  }

  void _showCalibrationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Calibration Complete!'),
          ],
        ),
        content: const Text(
          'All fingers have been successfully calibrated. Your demo device is now ready to capture gestures.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isCalibrating = false;
                _currentFingerIndex = 0;
              });
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showQuickTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Quick Sensor Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Simulated sensor readings:'),
            const SizedBox(height: 16),
            ...FingerType.values.map((finger) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${finger.displayName} (${finger.shortCode})'),
                  Text('${(finger.index * 20 + 10)}°'),
                ],
              ),
            )),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hand Rotation (HR)'),
                Text('15°'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 