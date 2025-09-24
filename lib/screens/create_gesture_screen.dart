import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:uuid/uuid.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../widgets/hand_animation_widget.dart';
import '../models/workspace_model.dart';
import '../models/gesture_model.dart';
import '../services/database_service.dart';

class CreateGestureScreen extends StatefulWidget {
  final WorkspaceModel workspace;
  final GestureModel? gesture; // For editing existing gesture

  const CreateGestureScreen({
    super.key,
    required this.workspace,
    this.gesture,
  });

  @override
  State<CreateGestureScreen> createState() => _CreateGestureScreenState();
}

class _CreateGestureScreenState extends State<CreateGestureScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sensorController = TextEditingController();
  final Map<String, TextEditingController> _textControllers = {};
  final DatabaseService _databaseService = DatabaseService();
  
  late AnimationController _gestureAnimationController;
  bool _isLoading = false;
  bool _isCapturingGesture = false;
  int _currentStep = 0;
  
  // Sensor values
  int _thumbValue = 0;
  int _indexValue = 0;
  int _middleValue = 0;
  int _ringValue = 0;
  int _pinkyValue = 0;
  int _handRotationValue = 0;

  bool get isEditing => widget.gesture != null;

  @override
  void initState() {
    super.initState();
    
    _gestureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize text controllers for supported languages
    for (final lang in SupportedLanguage.values) {
      _textControllers[lang.code] = TextEditingController();
    }

    if (isEditing) {
      _loadExistingGesture();
    } else {
      // Set primary language text controller as required
      _textControllers[widget.workspace.language]?.text = '';
    }
  }

  void _loadExistingGesture() {
    final gesture = widget.gesture!;
    _nameController.text = gesture.name;
    
    // Load sensor data
    _thumbValue = gesture.sensorData.thumb;
    _indexValue = gesture.sensorData.indexFinger;
    _middleValue = gesture.sensorData.middle;
    _ringValue = gesture.sensorData.ring;
    _pinkyValue = gesture.sensorData.pinky;
    _handRotationValue = gesture.sensorData.handRotation;
    
    _updateSensorString();
    
    // Load text mappings
    for (final entry in gesture.textMappings.entries) {
      _textControllers[entry.key]?.text = entry.value;
    }
  }

  @override
  void dispose() {
    _gestureAnimationController.dispose();
    _nameController.dispose();
    _sensorController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
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
                child: _isCapturingGesture 
                    ? _buildGestureCaptureView() 
                    : _buildFormView(),
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
                  isEditing ? 'Edit Gesture' : 'Create Gesture',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _isCapturingGesture 
                      ? 'Capture hand gesture'
                      : 'Add gesture to ${widget.workspace.name}',
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

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimationLimiter(
        child: Form(
          key: _formKey,
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // Gesture Name
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.label_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Gesture Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Gesture Name',
                          hintText: 'e.g., Hello, Thank You, Help',
                          prefixIcon: Icon(Icons.pan_tool_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a gesture name';
                          }
                          if (value.trim().length < 2) {
                            return 'Gesture name must be at least 2 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Sensor Data Input
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sensors,
                              color: AppTheme.secondaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Sensor Data',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isCapturingGesture = true;
                              });
                              _startGestureCapture();
                            },
                            icon: const Icon(Icons.record_voice_over, size: 18),
                            label: const Text('Capture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Manual sensor input
                      TextFormField(
                        controller: _sensorController,
                        decoration: const InputDecoration(
                          labelText: 'Sensor String',
                          hintText: 'T{0-120}I{0-120}M{0-120}R{0-120}P{0-120}HR{-120-120}',
                          prefixIcon: Icon(Icons.code),
                          helperText: 'Format: T{thumb}I{index}M{middle}R{ring}P{pinky}HR{rotation}',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter sensor data or capture a gesture';
                          }
                          try {
                            GestureModel.parseSensorString(value.trim());
                            return null;
                          } catch (e) {
                            return 'Invalid sensor string format';
                          }
                        },
                        onChanged: _parseSensorString,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sensor sliders for manual adjustment
                      _buildSensorSliders(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Text Mappings
                _buildTextMappings(),
                
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGesture,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEditing ? 'Update Gesture' : 'Create Gesture'),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorSliders() {
    return Column(
      children: [
        _buildSensorSlider('Thumb (T)', _thumbValue, 0, 120, (value) {
          setState(() {
            _thumbValue = value.round();
            _updateSensorString();
          });
        }),
        _buildSensorSlider('Index (I)', _indexValue, 0, 120, (value) {
          setState(() {
            _indexValue = value.round();
            _updateSensorString();
          });
        }),
        _buildSensorSlider('Middle (M)', _middleValue, 0, 120, (value) {
          setState(() {
            _middleValue = value.round();
            _updateSensorString();
          });
        }),
        _buildSensorSlider('Ring (R)', _ringValue, 0, 120, (value) {
          setState(() {
            _ringValue = value.round();
            _updateSensorString();
          });
        }),
        _buildSensorSlider('Pinky (P)', _pinkyValue, 0, 120, (value) {
          setState(() {
            _pinkyValue = value.round();
            _updateSensorString();
          });
        }),
        _buildSensorSlider('Hand Rotation (HR)', _handRotationValue, -120, 120, (value) {
          setState(() {
            _handRotationValue = value.round();
            _updateSensorString();
          });
        }),
      ],
    );
  }

  Widget _buildSensorSlider(
    String label, 
    int value, 
    int min, 
    int max, 
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextMappings() {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.translate,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Text Mappings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the text that should be spoken for this gesture in different languages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          
          // Primary language (required)
          _buildLanguageTextInput(
            SupportedLanguage.fromCode(widget.workspace.language),
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          // Other languages (optional)
          ExpansionTile(
            title: const Text('Additional Languages'),
            subtitle: const Text('Optional: Add translations for other languages'),
            children: SupportedLanguage.values
                .where((lang) => lang.code != widget.workspace.language)
                .map((lang) => _buildLanguageTextInput(lang))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTextInput(SupportedLanguage language, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _textControllers[language.code],
        decoration: InputDecoration(
          labelText: '${language.flag} ${language.name}${isRequired ? ' *' : ''}',
          hintText: 'Enter text for this gesture...',
          prefixIcon: Text(
            language.flag,
            style: const TextStyle(fontSize: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
        ),
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter text for the primary language';
          }
          return null;
        } : null,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
      ),
    );
  }

  Widget _buildGestureCaptureView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress indicator
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: AppTheme.dividerColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                ),
              ],
            ),
          ),
          
          // Hand animation
          HandAnimationWidget(
            highlightedFinger: _getCurrentHighlightedFinger(),
            animationDuration: const Duration(milliseconds: 1500),
          ),
          
          const SizedBox(height: 30),
          
          // Instructions
          GradientCard(
            child: Column(
              children: [
                Text(
                  _getStepTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getStepDescription(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Simulated sensor readings
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
                        'Live Sensor Data',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLiveSensorReading('T', _thumbValue),
                          _buildLiveSensorReading('I', _indexValue),
                          _buildLiveSensorReading('M', _middleValue),
                          _buildLiveSensorReading('R', _ringValue),
                          _buildLiveSensorReading('P', _pinkyValue),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLiveSensorReading('HR', _handRotationValue, isRotation: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isCapturingGesture = false;
                            _currentStep = 0;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextCaptureStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        child: Text(_currentStep == 2 ? 'Complete' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSensorReading(String label, int value, {bool isRotation = false}) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value${isRotation ? '°' : ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  FingerType _getCurrentHighlightedFinger() {
    switch (_currentStep) {
      case 0:
        return FingerType.thumb;
      case 1:
        return FingerType.indexFinger;
      case 2:
        return FingerType.middle;
      default:
        return FingerType.thumb;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Position Your Hand';
      case 1:
        return 'Make the Gesture';
      case 2:
        return 'Hold Position';
      default:
        return 'Capture Gesture';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Place your hand in a comfortable position. Make sure all sensors are properly positioned on your fingers.';
      case 1:
        return 'Slowly form the gesture you want to capture. The sensors will detect the movement of each finger.';
      case 2:
        return 'Hold the gesture steady for a moment while we capture the final sensor readings.';
      default:
        return 'Follow the instructions to capture your gesture.';
    }
  }

  void _startGestureCapture() {
    _gestureAnimationController.repeat();
    // Simulate sensor data changes during capture
    _simulateSensorData();
  }

  void _simulateSensorData() {
    // Simulate realistic sensor data based on current step
    setState(() {
      switch (_currentStep) {
        case 0:
          _thumbValue = 20 + (_currentStep * 15);
          _indexValue = 10 + (_currentStep * 20);
          _middleValue = 15 + (_currentStep * 18);
          _ringValue = 25 + (_currentStep * 12);
          _pinkyValue = 30 + (_currentStep * 10);
          _handRotationValue = -10 + (_currentStep * 5);
          break;
        case 1:
          _thumbValue = 45 + (_currentStep * 10);
          _indexValue = 60 + (_currentStep * 15);
          _middleValue = 55 + (_currentStep * 12);
          _ringValue = 40 + (_currentStep * 8);
          _pinkyValue = 50 + (_currentStep * 6);
          _handRotationValue = 5 + (_currentStep * 3);
          break;
        case 2:
          _thumbValue = 75;
          _indexValue = 90;
          _middleValue = 85;
          _ringValue = 70;
          _pinkyValue = 65;
          _handRotationValue = 15;
          break;
      }
      _updateSensorString();
    });
  }

  void _nextCaptureStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _simulateSensorData();
    } else {
      // Complete capture
      setState(() {
        _isCapturingGesture = false;
        _currentStep = 0;
      });
      _gestureAnimationController.stop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gesture captured successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _updateSensorString() {
    _sensorController.text = 'T{$_thumbValue}I{$_indexValue}M{$_middleValue}R{$_ringValue}P{$_pinkyValue}HR{$_handRotationValue}';
  }

  void _parseSensorString(String sensorString) {
    try {
      final sensorData = GestureModel.parseSensorString(sensorString);
      setState(() {
        _thumbValue = sensorData.thumb;
        _indexValue = sensorData.indexFinger;
        _middleValue = sensorData.middle;
        _ringValue = sensorData.ring;
        _pinkyValue = sensorData.pinky;
        _handRotationValue = sensorData.handRotation;
      });
    } catch (e) {
      // Invalid format, ignore
    }
  }

  Future<void> _saveGesture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uuid = const Uuid();
      final now = DateTime.now();
      
      // Parse sensor data
      final sensorData = GestureModel.parseSensorString(_sensorController.text.trim());
      
      // Build text mappings
      final textMappings = <String, String>{};
      for (final entry in _textControllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          textMappings[entry.key] = entry.value.text.trim();
        }
      }

      final gesture = isEditing
          ? widget.gesture!.copyWith(
              name: _nameController.text.trim(),
              sensorData: sensorData,
              textMappings: textMappings,
              updatedAt: now,
            )
          : GestureModel(
              id: uuid.v4(),
              name: _nameController.text.trim(),
              workspaceId: widget.workspace.id,
              sensorData: sensorData,
              textMappings: textMappings,
              createdAt: now,
              updatedAt: now,
            );

      if (isEditing) {
        await _databaseService.updateGesture(gesture);
      } else {
        await _databaseService.insertGesture(gesture);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                  ? 'Gesture updated successfully' 
                  : 'Gesture created successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving gesture: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 