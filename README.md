# SpeakTHands 🤟

**Transform Hand Gestures into Speech through ESP32 Flex Sensor Data via Bluetooth**

*A project by HandsonSync*

## Overview

SpeakTHands is a Flutter mobile application that enables users to map hand gestures captured through flex sensor data from ESP32 devices via Bluetooth connection. The app converts these gestures into text and then uses text-to-speech functionality to give voice to hand movements.

## Features

### Current Implementation
- ✅ **Dark Theme UI**: Modern, accessible dark theme with gradient backgrounds
- ✅ **Bluetooth Ready**: Configured permissions and dependencies for ESP32 communication
- ✅ **Text-to-Speech**: Integrated TTS capabilities for voice output
- ✅ **Responsive Design**: Beautiful, animated UI with custom components
- ✅ **Cross-Platform**: Supports both Android and iOS

### Planned Features
- 🔄 **Bluetooth Communication**: Connect and communicate with ESP32 devices
- 🔄 **Gesture Recognition**: Map flex sensor data to predefined gestures
- 🔄 **Custom Gesture Creation**: Allow users to create and train custom gestures
- 🔄 **Voice Customization**: Multiple TTS voices and settings
- 🔄 **Gesture Library**: Pre-built gesture database
- 🔄 **Real-time Feedback**: Live sensor data visualization
- 🔄 **Settings & Preferences**: User customization options

## Technical Stack

### Frontend
- **Flutter 3.8.1+**: Cross-platform mobile development
- **Material Design 3**: Modern UI components
- **Provider**: State management
- **Custom Animations**: Smooth transitions and interactions

### Key Dependencies
- `flutter_bluetooth_serial`: Bluetooth communication
- `flutter_tts`: Text-to-speech functionality
- `permission_handler`: Runtime permissions
- `provider`: State management
- `material_design_icons_flutter`: Extended icon set
- `animated_text_kit`: Text animations
- `fl_chart`: Data visualization
- `lottie`: Advanced animations
- `shared_preferences`: Local storage

### Hardware Integration
- **ESP32**: Microcontroller for sensor data collection
- **Flex Sensors**: Hand gesture detection
- **Bluetooth Classic/LE**: Wireless communication

## Project Structure

```
lib/
├── main.dart              # App entry point
├── themes/
│   └── app_theme.dart     # Dark theme configuration
├── screens/
│   ├── splash_screen.dart # Animated splash screen
│   └── home_screen.dart   # Main dashboard
├── widgets/
│   └── gradient_card.dart # Reusable UI components
├── services/              # Bluetooth & TTS services (planned)
├── models/                # Data models (planned)
└── utils/                 # Helper functions (planned)
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Android Studio / Xcode for platform-specific development
- ESP32 device with flex sensors (for hardware integration)

### Installation

1. **Clone the repository**
   ```bash
   cd /path/to/your/projects
   # Project is already created in: /Users/anan/Documents/research/speakThroughHand/SpeakTHands
   ```

2. **Install dependencies**
   ```bash
   cd SpeakTHands
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios
   ```

### Platform Configuration

#### Android
- **Permissions**: Bluetooth, Location (for device scanning)
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: Latest

#### iOS
- **Permissions**: Bluetooth, Location, Microphone
- **Min iOS**: 12.0
- **Deployment Target**: Latest

## App Architecture

### Theme System
- **Dark-first Design**: Optimized for low-light usage
- **Gradient Backgrounds**: Modern visual appeal
- **Custom Color Palette**: Purple/teal accent colors
- **Poppins Font**: Clean, readable typography

### Screen Flow
1. **Splash Screen**: Animated app introduction
2. **Home Dashboard**: Connection status, quick actions, recent activity
3. **Gesture Management**: Configure and manage gestures (planned)
4. **Settings**: App preferences and configuration (planned)

### State Management
- Provider pattern for reactive UI updates
- Separation of concerns between UI and business logic
- Centralized theme and configuration management

## Development Roadmap

### Phase 1: Foundation ✅
- [x] Project setup and configuration
- [x] Dark theme implementation
- [x] Basic UI structure
- [x] Dependency integration

### Phase 2: Core Features (Next)
- [ ] Bluetooth service implementation
- [ ] ESP32 communication protocol
- [ ] Basic gesture recognition
- [ ] TTS integration

### Phase 3: Advanced Features
- [ ] Custom gesture creation
- [ ] Gesture training and machine learning
- [ ] Advanced UI/UX improvements
- [ ] Data persistence and sync

### Phase 4: Polish & Distribution
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] App store preparation
- [ ] Documentation completion

## Contributing

This is a project by HandsonSync. For development guidelines and contribution instructions, please refer to the internal development documentation.

## Hardware Requirements

### ESP32 Setup
- ESP32 development board
- 9x 44E Hall Effect Sensor
- Resistors and breadboard for circuit assembly
- Bluetooth Classic/LE capability

### Recommended Specifications
- Android 6.0+ or iOS 12.0+
- Bluetooth 4.0+ support
- Minimum 2GB RAM
- 100MB free storage

## License

© 2024 HandsonSync. All rights reserved.

## Contact

For questions, support, or collaboration opportunities, please contact the HandsonSync team.

---

**SpeakTHands** - Giving voice to gestures, one hand at a time. 🤟
