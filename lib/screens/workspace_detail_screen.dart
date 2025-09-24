import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../models/workspace_model.dart';
import '../models/gesture_model.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import 'create_gesture_screen.dart';

class WorkspaceDetailScreen extends StatefulWidget {
  final WorkspaceModel workspace;

  const WorkspaceDetailScreen({super.key, required this.workspace});

  @override
  State<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends State<WorkspaceDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();
  List<GestureModel> _gestures = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _playingGestureId;

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gestures = await _databaseService.getGesturesByWorkspace(widget.workspace.id);
      setState(() {
        _gestures = gestures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading gestures: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<GestureModel> get _filteredGestures {
    if (_searchQuery.isEmpty) {
      return _gestures;
    }
    return _gestures.where((gesture) {
      return gesture.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             gesture.textMappings.values.any((text) => 
                 text.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final language = SupportedLanguage.fromCode(widget.workspace.language);
    
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
              _buildWorkspaceHeader(language),
              _buildSearchBar(),
              Expanded(
                child: _isLoading ? _buildLoadingView() : _buildGestureList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGesture(),
        icon: const Icon(Icons.add),
        label: const Text('Add Gesture'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.workspace.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _loadGestures,
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader(SupportedLanguage language) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      language.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workspace.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            MdiIcons.gestureSwipe,
                            size: 16,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_gestures.length} gestures',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.language,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            language.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search gestures...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading gestures...',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureList() {
    final filteredGestures = _filteredGestures;
    
    if (filteredGestures.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGestures,
      backgroundColor: AppTheme.cardColor,
      color: AppTheme.primaryColor,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredGestures.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildGestureCard(filteredGestures[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : MdiIcons.gestureSwipe,
                size: 60,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'No Gestures Found' : 'No Gestures Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch 
                  ? 'Try adjusting your search terms'
                  : 'Create your first gesture to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!hasSearch)
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateGesture(),
                icon: const Icon(Icons.add),
                label: const Text('Create Gesture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureCard(GestureModel gesture) {
    final primaryText = gesture.textMappings[widget.workspace.language] ?? 
                       gesture.textMappings.values.first;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        child: InkWell(
          onTap: () => _showGestureDetail(gesture),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gesture Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pan_tool_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gesture.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            primaryText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textSecondary,
                      ),
                      color: AppTheme.cardColor,
                      onSelected: (value) => _handleGestureAction(value, gesture),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(
                                _playingGestureId == gesture.id 
                                    ? Icons.stop 
                                    : Icons.play_arrow,
                                size: 20,
                                color: _playingGestureId == gesture.id 
                                    ? AppTheme.errorColor 
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(_playingGestureId == gesture.id 
                                  ? 'Stop Audio' 
                                  : 'Play Audio'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20),
                              SizedBox(width: 12),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sensor Data Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSensorPreview('T', gesture.sensorData.thumb),
                      _buildSensorPreview('I', gesture.sensorData.indexFinger),
                      _buildSensorPreview('M', gesture.sensorData.middle),
                      _buildSensorPreview('R', gesture.sensorData.ring),
                      _buildSensorPreview('P', gesture.sensorData.pinky),
                      _buildSensorPreview('HR', gesture.sensorData.handRotation, isRotation: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Updated ${_formatDate(gesture.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorPreview(String label, int value, {bool isRotation = false}) {
    final percentage = isRotation 
        ? ((value + 120) / 240) // Convert -120 to 120 range to 0-1
        : (value / 120); // Convert 0-120 range to 0-1
    
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value${isRotation ? '°' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToCreateGesture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGestureScreen(workspace: widget.workspace),
      ),
    );

    if (result == true) {
      _loadGestures();
    }
  }

  void _showGestureDetail(GestureModel gesture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pan_tool_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gesture.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Text Mappings:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...gesture.textMappings.entries.map((entry) {
              final lang = SupportedLanguage.fromCode(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '${lang.name}: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Sensor Data: ${gesture.sensorString}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGestureAction(String action, GestureModel gesture) {
    switch (action) {
      case 'play':
        _playGesture(gesture);
        break;
      case 'edit':
        _editGesture(gesture);
        break;
      case 'duplicate':
        _duplicateGesture(gesture);
        break;
      case 'delete':
        _deleteGesture(gesture);
        break;
    }
  }

  void _playGesture(GestureModel gesture) async {
    if (_playingGestureId == gesture.id) {
      // Stop current playback
      await _ttsService.stop();
      setState(() {
        _playingGestureId = null;
      });
      return;
    }

    setState(() {
      _playingGestureId = gesture.id;
    });

    try {
      // Get the text for the workspace's primary language
      final text = gesture.textMappings[widget.workspace.language] ?? 
                   gesture.textMappings.values.first;
      
      if (text.isEmpty) {
        throw Exception('No text found for this gesture');
      }

      // Get language code for TTS
      final languageCode = _ttsService.getLanguageCodeForSupportedLanguage(
        SupportedLanguage.fromCode(widget.workspace.language)
      );

      final success = await _ttsService.speak(text, languageCode: languageCode);
      
      if (!success) {
        throw Exception('Failed to play audio');
      }

      // Wait a moment then reset playing state
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _playingGestureId == gesture.id) {
        setState(() {
          _playingGestureId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playingGestureId = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing gesture: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _editGesture(GestureModel gesture) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGestureScreen(
          workspace: widget.workspace,
          gesture: gesture,
        ),
      ),
    );

    if (result == true) {
      _loadGestures();
    }
  }

  void _duplicateGesture(GestureModel gesture) {
    // TODO: Implement gesture duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gesture duplication coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _deleteGesture(GestureModel gesture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Gesture'),
        content: Text('Are you sure you want to delete "${gesture.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.deleteGesture(gesture.id);
                _loadGestures();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gesture deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting gesture: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
} 