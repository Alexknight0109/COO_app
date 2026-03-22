import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// Detect if running on Raspberry Pi for performance optimizations
bool get isRaspberryPi {
  if (!Platform.isLinux) return false;
  try {
    final result = File('/proc/cpuinfo').readAsStringSync();
    return result.contains('Raspberry') || result.contains('BCM');
  } catch (e) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // RPi Performance: Disable debug painting and checkerboards
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;
  
  // Enable fullscreen mode on launch
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [], // Hide all system UI overlays
  );
  
  // Set preferred orientations (optional - can be removed if rotation is needed)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Pre-load screen lock state before app starts
  final appProvider = AppProvider();
  await appProvider.loadScreenLockPasscode();
  
  runApp(AhuDashboardApp(appProvider: appProvider));
}

/// Custom scroll behavior that:
/// - Hides scrollbars completely (no side scrollbar)
/// - Enables touch scrolling on all devices
/// - Uses bouncing physics for natural touch feel
class TouchFriendlyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Return child directly without wrapping in Scrollbar - hides scrollbar completely
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use bouncing physics for natural touch feel
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class AhuDashboardApp extends StatelessWidget {
  final AppProvider appProvider;
  
  const AhuDashboardApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use pre-loaded provider with lock state already initialized
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AHU Control Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Apply global touch-friendly scroll behavior (no scrollbar, touch/drag everywhere)
            scrollBehavior: TouchFriendlyScrollBehavior(),
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
