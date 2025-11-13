# ALMED OPS Control System - Flutter Frontend

Flutter application with Material Design 3, smooth animations, and consistent UI across platforms.

## Features

✨ **Material Design 3** - Modern Material Design implementation  
🎨 **Dark/Light Theme** - Beautiful theme system with smooth transitions  
🚀 **Smooth Animations** - Built with flutter_animate for fluid motion  
📱 **Cross-Platform** - Consistent UI on Web, iOS, Android, Desktop  
🎯 **Responsive Layout** - Adapts to different screen sizes  

## Setup

### Prerequisites

1. **Install Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install
   - Make sure Flutter is in your PATH
   - Verify: `flutter doctor`

2. **Install Dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

   For specific platforms:
   ```bash
   flutter run -d chrome        # Web
   flutter run -d windows       # Windows Desktop
   flutter run -d macos         # macOS Desktop
   flutter run -d linux         # Linux Desktop
   flutter run -d ios           # iOS
   flutter run -d android       # Android
   ```

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── theme/                 # Theme system
│   │   ├── app_theme.dart    # Material Design 3 themes
│   │   └── theme_provider.dart
│   ├── routes/                # Navigation
│   │   └── app_router.dart
│   ├── screens/               # All app screens
│   │   ├── dashboard/
│   │   ├── tasks/
│   │   ├── messages/
│   │   ├── calendar/
│   │   └── ...
│   ├── widgets/               # Reusable widgets
│   │   ├── main_layout.dart
│   │   ├── app_sidebar.dart
│   │   ├── app_header.dart
│   │   └── ...
│   └── models/                # Data models
│       └── task_model.dart
└── pubspec.yaml              # Dependencies
```

## Theme System

The app uses Material Design 3 with custom color schemes:

- **Dark Theme** (Primary): Deep navy background (#0D0F21)
- **Light Theme** (Secondary): Light background (#F8F9FE)
- **Accent Colors**: Purple (#8B5CF6) → Blue (#3B82F6) gradient

Theme preference is saved in SharedPreferences and persists across app restarts.

## Screens

- **Dashboard** - Stats cards with animations
- **Tasks** - Kanban board with drag-and-drop (ready)
- **Messages** - Chat interface with Material Design
- **Calendar** - Table calendar widget
- **Projects** - Project management (placeholder)
- **Site Logs** - Site logging (placeholder)
- **Complaints** - Service tickets (placeholder)
- **Factory** - Production control (placeholder)
- **Inventory** - Stock management (placeholder)
- **Accounts** - Payment tracking (placeholder)
- **HR** - Employee management (placeholder)
- **Reports** - Reports module (placeholder)
- **Settings** - App settings with theme toggle

## Animations

Using `flutter_animate` package for:
- Fade in animations
- Slide transitions
- Scale effects
- Shimmer effects
- Staggered animations

## API Integration

To connect with the backend API:

1. Create API service in `lib/services/api_service.dart`
2. Use `dio` or `http` package for API calls
3. Update models to match backend responses
4. Implement state management (Provider/Riverpod)

## Building for Production

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Mobile
```bash
flutter build apk --release          # Android
flutter build ios --release          # iOS
```

## Dependencies

- `go_router` - Navigation
- `flutter_animate` - Animations
- `provider` - State management
- `material_design_icons_flutter` - Material icons
- `table_calendar` - Calendar widget
- `dio` / `http` - API calls
- `shared_preferences` - Local storage
- `socket_io_client` - Real-time communication

## Next Steps

1. ✅ Theme system - Complete
2. ✅ Dashboard - Complete
3. ✅ Tasks screen - Complete (UI ready)
4. ✅ Messages screen - Complete
5. ✅ Calendar - Complete
6. ⏳ Implement API integration
7. ⏳ Add drag-and-drop for tasks
8. ⏳ Complete remaining module screens
9. ⏳ Add authentication flow
10. ⏳ Implement real-time features (WebSocket)
