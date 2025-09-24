import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../themes/app_theme.dart';
import '../widgets/gradient_card.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TTSService _ttsService = TTSService();
  final _openaiKeyController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _ttsService.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
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
                child: _buildSettingsList(),
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
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Customize your SpeakTHands experience',
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

  Widget _buildSettingsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // User Profile
              _buildUserProfileCard(),
              
              const SizedBox(height: 20),
              
              // Voice & TTS Settings
              _buildVoiceSettingsCard(),
              
              const SizedBox(height: 20),
              
              // OpenAI Configuration
              _buildOpenAICard(),
              
              const SizedBox(height: 20),
              
              // App Information
              _buildAppInfoCard(),
              
              const SizedBox(height: 20),
              
              // Legal & Support
              _buildLegalCard(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
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
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'User Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Profile Picture
          Center(
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 3,
                  ),
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImage == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Text(
              _profileImage == null 
                  ? 'Tap to add profile picture'
                  : 'Tap to change profile picture',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettingsCard() {
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
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Voice Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // TTS Provider Selection
          Text(
            'Text-to-Speech Provider',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildProviderOption(
                  TTSProvider.flutter,
                  'System TTS',
                  'Use device\'s built-in text-to-speech',
                  Icons.phone_android,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProviderOption(
                  TTSProvider.openai,
                  'OpenAI TTS',
                  'High-quality AI voices (requires API key)',
                  Icons.auto_awesome,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Voice Controls
          _buildSliderSetting(
            'Speech Rate',
            _ttsService.speechRate,
            0.1,
            1.0,
            (value) async {
              await _ttsService.setSpeechRate(value);
              setState(() {});
            },
          ),
          
          _buildSliderSetting(
            'Volume',
            _ttsService.volume,
            0.0,
            1.0,
            (value) async {
              await _ttsService.setVolume(value);
              setState(() {});
            },
          ),
          
          _buildSliderSetting(
            'Pitch',
            _ttsService.pitch,
            0.5,
            2.0,
            (value) async {
              await _ttsService.setPitch(value);
              setState(() {});
            },
          ),
          
          const SizedBox(height: 20),
          
          // Test Voice Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testVoice,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Voice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenAICard() {
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
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'OpenAI Configuration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (_ttsService.hasOpenAIKey)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Connected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Enter your OpenAI API key to use high-quality AI voices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _openaiKeyController,
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveOpenAIKey,
              ),
            ),
            obscureText: true,
          ),
          
          if (_ttsService.currentProvider == TTSProvider.openai) ...[
            const SizedBox(height: 20),
            
            Text(
              'Voice Selection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<OpenAIVoice>(
              value: _ttsService.openaiVoice,
              decoration: const InputDecoration(
                labelText: 'OpenAI Voice',
                prefixIcon: Icon(Icons.voice_over_off),
              ),
              items: OpenAIVoice.values.map((voice) {
                return DropdownMenuItem(
                  value: voice,
                  child: Text(voice.description),
                );
              }).toList(),
              onChanged: (voice) async {
                if (voice != null) {
                  await _ttsService.setOpenAIVoice(voice);
                  setState(() {});
                }
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Get your API key from platform.openai.com/api-keys',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
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
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'App Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Build', '1'),
          _buildInfoRow('Developer', 'HandsonSync'),
          _buildInfoRow('Project', 'SpeakTHands'),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showUserManual,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('User Manual'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAbout,
                  icon: const Icon(Icons.info),
                  label: const Text('About'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
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
                  color: AppTheme.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Legal & Support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildLegalOption(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description,
            _showTermsOfService,
          ),
          
          _buildLegalOption(
            'Privacy Policy',
            'Learn how we protect your data',
            Icons.privacy_tip,
            _showPrivacyPolicy,
          ),
          
          _buildLegalOption(
            'Connect to Cloud',
            'Sync your data across devices (Coming Soon)',
            Icons.cloud_upload,
            null, // Disabled for now
            isComingSoon: true,
          ),
          
          _buildLegalOption(
            'Contact Support',
            'Get help with any issues',
            Icons.support_agent,
            _contactSupport,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderOption(
    TTSProvider provider,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _ttsService.currentProvider == provider;
    final isEnabled = provider == TTSProvider.flutter || _ttsService.hasOpenAIKey;
    
    return GestureDetector(
      onTap: isEnabled ? () async {
        await _ttsService.setTTSProvider(provider);
        setState(() {});
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.secondaryColor.withOpacity(0.2)
              : AppTheme.surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.secondaryColor 
                : AppTheme.dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled 
                  ? (isSelected ? AppTheme.secondaryColor : AppTheme.textPrimary)
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isEnabled 
                        ? (isSelected ? AppTheme.secondaryColor : AppTheme.textPrimary)
                        : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isEnabled)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'API Key Required',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
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
                value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  Widget _buildLegalOption(
    String title,
    String description,
    IconData icon,
    VoidCallback? onTap,
    {bool isComingSoon = false}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (onTap != null && !isComingSoon) 
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: (onTap != null && !isComingSoon) 
                ? AppTheme.primaryColor
                : AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: (onTap != null && !isComingSoon) 
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
            ),
            if (isComingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming Soon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        trailing: (onTap != null && !isComingSoon) 
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.surfaceColor.withOpacity(0.3),
      ),
    );
  }

  // Action methods
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _saveOpenAIKey() async {
    final key = _openaiKeyController.text.trim();
    if (key.isNotEmpty) {
      await _ttsService.setOpenAIApiKey(key);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OpenAI API key saved!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _testVoice() async {
    try {
      final success = await _ttsService.testTTS();
      if (!success) {
        throw Exception('Failed to test voice');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice test successful!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice test failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showUserManual() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('User Manual'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Getting Started:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. Connect your ESP32 device or use Demo Device'),
              Text('2. Create workspaces to organize gestures'),
              Text('3. Add gestures with sensor data and text'),
              Text('4. Configure voice settings for TTS'),
              SizedBox(height: 16),
              Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Multi-language support'),
              Text('• OpenAI TTS integration'),
              Text('• Gesture capture simulation'),
              Text('• SQLite data storage'),
            ],
          ),
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('About SpeakTHands'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SpeakTHands transforms hand gestures into speech using ESP32 flex sensor data and Bluetooth connectivity.'),
            SizedBox(height: 16),
            Text('Developed by HandsonSync as part of the "Speak Through Hands" project.'),
            SizedBox(height: 16),
            Text('© 2024 HandsonSync. All rights reserved.'),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service for SpeakTHands\n\n'
            '1. Acceptance of Terms\n'
            'By using SpeakTHands, you agree to these terms.\n\n'
            '2. Use License\n'
            'This app is provided for personal and educational use.\n\n'
            '3. Privacy\n'
            'We respect your privacy. All data is stored locally on your device.\n\n'
            '4. Disclaimers\n'
            'The app is provided "as is" without warranties.\n\n'
            '5. Contact\n'
            'For questions, contact HandsonSync team.',
          ),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for SpeakTHands\n\n'
            '1. Information We Collect\n'
            'We collect gesture data and text mappings you create.\n\n'
            '2. How We Use Information\n'
            'Data is used solely for app functionality.\n\n'
            '3. Data Storage\n'
            'All data is stored locally on your device using SQLite.\n\n'
            '4. Third-Party Services\n'
            'OpenAI TTS service may be used if you provide an API key.\n\n'
            '5. Data Security\n'
            'We implement security measures to protect your data.\n\n'
            '6. Contact\n'
            'Questions about privacy can be directed to HandsonSync.',
          ),
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

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Contact Support'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Need help with SpeakTHands?'),
            SizedBox(height: 16),
            Text('Contact HandsonSync team:'),
            SizedBox(height: 8),
            Text('• Email: support@handsonsync.com'),
            Text('• Website: www.handsonsync.com'),
            Text('• Project: Speak Through Hands'),
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