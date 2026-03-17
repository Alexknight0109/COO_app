# ALMED AHU Dashboard - Flutter-Pi Touch Interface

A professional touch-friendly dashboard for hospital AHU (Air Handling Unit) control, built with Flutter-Pi for Raspberry Pi deployment.

## 🎯 Features

### Core Functionality
- **Dual User Roles**: Hospital (monitoring) and Admin (full control)
- **Real-time MQTT Integration**: Live data from ESP32 AHU units
- **Touch-Optimized UI**: Designed for kiosk mode on Raspberry Pi
- **Theme Support**: Light (white/blue) and Dark (black/blue) modes
- **Professional Branding**: ALMED logo and custom Vendura font

### UI Components
- **Login Screen**: Role selection with ALMED branding
- **Dashboard**: AHU unit cards with status overview
- **AHU Control**: Temperature/humidity setpoints, motor controls
- **Admin Settings**: WiFi and MQTT broker provisioning
- **Log Viewer**: Collapsible real-time logs with timestamps

## 🚀 Quick Start

### Prerequisites
- Raspberry Pi (4B recommended)
- Flutter SDK
- MQTT broker (Mosquitto)

### Installation

1. **Clone and Setup**:
   ```bash
   cd /home/almedproto/Documents/almed_ahu/ahu_dashboard
   flutter pub get
   ```

2. **Add Assets**:
   - Save logo images to `assets/images/`:
     - `logo_dark.png` (dark text for light mode)
     - `logo_light.png` (light text for dark mode)
   - Download Vendura font from [DaFont](https://www.dafont.com/vendura.font)
   - Save `Vendura-SemiBold-Demo.otf` to `assets/fonts/`

3. **Enable Custom Font**:
   ```yaml
   # In pubspec.yaml, uncomment:
   fonts:
     - family: Verdana
       fonts:
         - asset: assets/fonts/Vendura-SemiBold-Demo.otf
           weight: 600
   ```

4. **Run Locally**:
   ```bash
   flutter run -d linux
   ```

## 🎨 UI Design

### Theme System
- **Light Mode**: White/blue gradient backgrounds
- **Dark Mode**: Black/blue gradient backgrounds
- **Consistent Colors**: Blue primary, no orange except success/error
- **Professional Cards**: Rounded corners, subtle borders

### Branding
- **ALMED Logo**: Theme-aware switching
- **Custom Font**: Vendura serif for "ALMED" text
- **Typography**: Clean, modern, touch-friendly
- **Spacing**: Optimized for touch interaction

### Performance Optimizations
- **Debounced Updates**: 100ms delay for MQTT data
- **Selector Widgets**: Targeted rebuilds only
- **Smooth Animations**: Fade-in, scale effects
- **Memory Efficient**: Minimal widget rebuilds

## 📡 MQTT Integration

### Topics Structure
```
almed/ahu/{hospital}/{unit}/{id}/
├── telemetry    # Real-time sensor data
├── state        # AHU operational state
├── log          # System logs
├── status       # Connection status
├── cmd          # Commands (start/stop/setpoints)
└── provision    # WiFi/broker settings
```

### Data Models
- **AhuTelemetry**: Temperature, humidity, motor status
- **AhuState**: Run state, setpoints, component status
- **AhuLog**: Timestamped log messages
- **AhuUnit**: Unit identification and naming

### ESP32 Integration
- **Sensors**: SHT45 temperature/humidity
- **Motors**: M1 (drain), M2 (filter clean)
- **Relays**: CP (compressor), Heater
- **Control**: Start/stop, setpoint adjustment

## 🏥 User Roles

### Hospital User
- **View Only**: Monitor AHU status and readings
- **Dashboard**: AHU unit cards with real-time data
- **Logs**: View system logs and alerts
- **No Control**: Cannot modify settings

### Admin User
- **Full Control**: Start/stop AHU units
- **Setpoints**: Adjust temperature/humidity targets
- **Motor Control**: Manual drain/filter operations
- **Provisioning**: WiFi and MQTT broker setup
- **Logs**: Full system access

## 🔧 Technical Architecture

### State Management
- **Provider Pattern**: Centralized app state
- **AppProvider**: MQTT data, AHU units, connections
- **ThemeProvider**: Light/dark mode switching
- **Debounced Updates**: Performance optimization

### Services
- **MqttService**: Connection, subscriptions, publishing
- **Stream Controllers**: Real-time data streams
- **Error Handling**: Connection recovery, fallbacks

### Widgets
- **Reusable Components**: Sensor displays, motor status
- **Optimized Builds**: Selector-based updates
- **Touch Targets**: Minimum 44px touch areas
- **Accessibility**: Screen reader support

## 📱 Screen Layouts

### Login Screen
- **ALMED Branding**: Logo and custom font
- **Role Selection**: Hospital vs Admin cards
- **Theme Toggle**: Sun/moon icon
- **Gradient Background**: Theme-aware colors

### Dashboard
- **AHU Cards**: Status, sensors, quick actions
- **Connection Status**: MQTT indicator
- **Navigation**: Back to login, logout
- **Empty State**: ALMED logo when no units

### AHU Control
- **Real-time Data**: Temperature, humidity, motors
- **Setpoint Controls**: Temperature/humidity targets
- **Motor Status**: Drain and filter indicators
- **Logs Section**: Collapsible real-time logs
- **Start/Stop**: Primary control button

### Admin Settings
- **AHU Selection**: Dropdown with ALMED branding
- **WiFi Provisioning**: Primary and secondary networks
- **MQTT Broker**: Host and port configuration
- **Status Feedback**: Success/error messages

## 🎯 Performance Features

### Optimizations
- **Debounced MQTT**: 100ms delay prevents UI lag
- **Selector Widgets**: Only rebuild changed components
- **Lazy Loading**: Logs load on demand
- **Memory Management**: Efficient state updates

### Touch Optimization
- **Large Touch Targets**: 44px minimum
- **Smooth Scrolling**: Hardware acceleration
- **Gesture Support**: Swipe, tap, long press
- **Visual Feedback**: Button states, animations

## 🔒 Security & Reliability

### MQTT Security
- **Connection Recovery**: Auto-reconnect on failure
- **Error Handling**: Graceful degradation
- **Data Validation**: JSON parsing with fallbacks
- **Status Monitoring**: Connection health checks

### UI Reliability
- **Fallback Assets**: Default icons if images missing
- **Error Boundaries**: Graceful error handling
- **State Persistence**: Theme preferences saved
- **Offline Support**: Cached data display

## 📊 Data Flow

```
ESP32 → MQTT Broker → Flutter App → UI Updates
  ↓           ↓            ↓           ↓
Sensors → Telemetry → Provider → Widgets
  ↓           ↓            ↓           ↓
Motors → State Data → Selector → Rebuild
  ↓           ↓            ↓           ↓
Logs → Log Data → Stream → Display
```

## 🎨 Customization

### Branding
- **Logo Images**: Replace in `assets/images/`
- **Custom Font**: Add to `assets/fonts/`
- **Colors**: Modify `lib/theme/app_theme.dart`
- **Layout**: Adjust screen components

### MQTT Topics
- **Topic Structure**: Modify in `lib/services/mqtt_service.dart`
- **Data Parsing**: Update model classes
- **Commands**: Add new control functions

### UI Themes
- **Color Schemes**: Light/dark mode colors
- **Gradients**: Background styling
- **Typography**: Font families and sizes
- **Spacing**: Padding and margins

## 🚀 Deployment

See `DEPLOYMENT.md` for Raspberry Pi kiosk setup, Flutter-Pi installation, and production deployment instructions.

## 📝 Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/               # Data models
├── providers/            # State management
├── screens/              # UI screens
├── services/             # MQTT service
├── theme/               # Theme configuration
└── widgets/             # Reusable components
```

### Key Files
- **main.dart**: App initialization, routing
- **app_provider.dart**: Central state management
- **mqtt_service.dart**: MQTT communication
- **app_theme.dart**: Light/dark themes
- **login_screen.dart**: Role selection
- **dashboard_screen.dart**: AHU overview
- **ahu_control_screen.dart**: Unit control
- **admin_screen.dart**: System settings

## 🔧 Troubleshooting

### Common Issues
- **Font Not Loading**: Check `pubspec.yaml` fonts section
- **Images Missing**: Verify `assets/images/` files
- **MQTT Connection**: Check broker settings
- **Performance**: Monitor debounce settings

### Debug Mode
```bash
flutter run -d linux --verbose
```

### Logs
- **MQTT Logs**: Connection status in console
- **App Logs**: Flutter debug output
- **Error Handling**: Graceful fallbacks

## 📄 License

This project is for ALMED hospital AHU control systems. All rights reserved.

---

**Built with Flutter-Pi for Raspberry Pi touch interfaces** 🚀
