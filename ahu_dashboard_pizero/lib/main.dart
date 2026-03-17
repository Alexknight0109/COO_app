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

/// Detect if running on Raspberry Pi
bool get isRaspberryPi {
  if (!Platform.isLinux) return false;
  try {
    final result = File('/proc/cpuinfo').readAsStringSync();
    return result.contains('Raspberry') || result.contains('BCM');
  } catch (e) {
    return false;
  }
}

/// Detect if running specifically on Pi Zero 2W.
/// The Zero 2W reports "Raspberry Pi Zero 2" in /proc/cpuinfo (Revision 902120).
bool get isPiZero2W {
  if (!Platform.isLinux) return false;
  try {
    final cpuinfo = File('/proc/cpuinfo').readAsStringSync();
    // Hardware field matches BCM2835 (all Zeros use this), but the Model line
    // distinguishes Zero 2W from Zero 1W.
    if (cpuinfo.contains('Zero 2')) return true;
    // Fallback: check /proc/device-tree/model which is more reliable
    final model = File('/proc/device-tree/model').readAsStringSync();
    return model.contains('Zero 2');
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable all debug overlays (always off in production)
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;

  // Pi Zero 2W has 512 MB RAM – hint the engine to keep the raster cache lean.
  // This reduces GPU memory pressure and prevents OOM on the constrained device.
  if (isPiZero2W || isRaspberryPi) {
    // Reduce picture cache to lower RAM footprint.  Default is 3; 1 is enough
    // for a single-screen kiosk that doesn't animate between many pages.
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20 MB
  }

  // Fullscreen immersive kiosk – hide all OS chrome
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Force landscape – the 7-inch Pi display is always landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Pre-load screen-lock state before the first frame renders
  final appProvider = AppProvider();
  await appProvider.loadScreenLockPasscode();

  runApp(AhuDashboardApp(appProvider: appProvider));
}

/// Scroll behaviour: no visible scrollbar, touch + mouse drag, bouncing physics.
class TouchFriendlyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics());
  }
}

class AhuDashboardApp extends StatelessWidget {
  final AppProvider appProvider;

  const AhuDashboardApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
            scrollBehavior: TouchFriendlyScrollBehavior(),
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
