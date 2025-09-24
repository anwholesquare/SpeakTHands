import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_card.dart';
import 'demo_device_screen.dart';
import 'workspace_screen.dart';
import 'settings_screen.dart';
import 'infer_screen.dart';
import 'bluetooth_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Gestures',
    'Infer',
    'Settings',
  ];

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
              // Custom App Bar
              _buildAppBar(),
              
              // Main Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App Logo
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
              Icons.pan_tool_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_selectedIndex],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Welcome to SpeakTHands',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          
          // Debug Bluetooth Test
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothTestScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.bluetooth,
              color: AppTheme.textPrimary,
            ),
          ),
          // Notification Icon
          IconButton(
            onPressed: () {
              // Handle notifications
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildGestures();
      case 2:
        return const InferScreen();
      case 3:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Card
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.bluetooth,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Device Connection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Not Connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle real Bluetooth connection
                        },
                        icon: const Icon(Icons.bluetooth),
                        label: const Text('Real Device'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DemoDeviceScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_android),
                        label: const Text('Demo Device'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.record_voice_over,
                  title: 'Voice Test',
                  subtitle: 'Test TTS',
                  onTap: () {
                    // Handle voice test
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:                  _buildQuickActionCard(
                   icon: Icons.workspace_premium,
                   title: 'Workspaces',
                   subtitle: 'Manage gestures',
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => const WorkspaceScreen(),
                       ),
                     );
                   },
                 ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          const SizedBox(height: 16),
          
          GradientCard(
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.pan_tool,
                  title: 'Gesture: Hello',
                  time: '2 minutes ago',
                ),
                const Divider(color: AppTheme.dividerColor),
                _buildActivityItem(
                  icon: Icons.volume_up,
                  title: 'Spoke: "Thank you"',
                  time: '5 minutes ago',
                ),
                const Divider(color: AppTheme.dividerColor),
                _buildActivityItem(
                  icon: Icons.bluetooth_connected,
                  title: 'Device connected',
                  time: '10 minutes ago',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGestures() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Access to Workspaces
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.gestureSwipe,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gesture Management',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Organize your sign language gestures into workspaces for different contexts and languages.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WorkspaceScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('Manage Workspaces'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Features Overview
          Text(
            'Features',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            icon: Icons.add_circle_outline,
            title: 'Create Gestures',
            description: 'Capture hand gestures using sensor data and map them to text',
            color: AppTheme.primaryColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildFeatureCard(
            icon: Icons.translate,
            title: 'Multi-language Support',
            description: 'Add text in multiple languages for the same gesture',
            color: AppTheme.secondaryColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildFeatureCard(
            icon: Icons.record_voice_over,
            title: 'Text-to-Speech',
            description: 'Convert gesture text to speech with natural voices',
            color: AppTheme.successColor,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Overview
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.cog,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'App Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Customize your SpeakTHands experience with voice settings, OpenAI integration, and more.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick Settings
          Text(
            'Quick Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          const SizedBox(height: 16),
          
          _buildQuickSettingCard(
            icon: Icons.record_voice_over,
            title: 'Voice & TTS',
            description: 'Configure text-to-speech settings and OpenAI voices',
            color: AppTheme.secondaryColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildQuickSettingCard(
            icon: Icons.person,
            title: 'User Profile',
            description: 'Manage your profile picture and personal settings',
            color: AppTheme.primaryColor,
          ),
          
          const SizedBox(height: 12),
          
          _buildQuickSettingCard(
            icon: Icons.info_outline,
            title: 'App Information',
            description: 'Version info, user manual, and support',
            color: AppTheme.successColor,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildQuickSettingCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  time,
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

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.viewDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.gestureSwipe),
            label: 'Gestures',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.handBackLeft),
            label: 'Infer',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.cog),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 