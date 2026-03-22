import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen_enhanced.dart';

/// Admin screen for WiFi provisioning and advanced settings
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? selectedAhuId;
  final _primarySsidController = TextEditingController();
  final _primaryPassController = TextEditingController();
  final _secondarySsidController = TextEditingController();
  final _secondaryPassController = TextEditingController();
  final _brokerHostController = TextEditingController();
  final _brokerPortController = TextEditingController(text: '1883');
  
  // Motor timing controllers
  final _m1StartController = TextEditingController(text: '10');
  final _m1PostController = TextEditingController(text: '10');
  final _m2IntervalController = TextEditingController(text: '30');
  final _m2RunController = TextEditingController(text: '10');
  final _m2DelayController = TextEditingController(text: '5');

  @override
  void dispose() {
    _primarySsidController.dispose();
    _primaryPassController.dispose();
    _secondarySsidController.dispose();
    _secondaryPassController.dispose();
    _brokerHostController.dispose();
    _brokerPortController.dispose();
    _m1StartController.dispose();
    _m1PostController.dispose();
    _m2IntervalController.dispose();
    _m2RunController.dispose();
    _m2DelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    Colors.white,
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button and logout - optimized for 7-inch Pi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // ALMED Branding
                    Text(
                      'ALMED',
                      style: TextStyle(
                        fontFamily: 'Verdana',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).dividerColor.withOpacity( 0.3),
                    ),
                    const SizedBox(width: 16),
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity( 0.1),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Admin Settings',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                        ),
                      ),
                    ),
                    // Exit to Desktop button (Kiosk mode exit)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity( 0.1),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.desktop_windows_rounded),
                        onPressed: () => _exitApplication(context),
                        tooltip: 'Exit to Desktop',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity( 0.1),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        tooltip: 'Logout',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final ahus = provider.ahuUnits;

                    if (ahus.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ALMED Logo
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Opacity(
                                opacity: 0.3,
                                child: Image.asset(
                                  isDark 
                                      ? 'assets/images/logo_light.png'
                                      : 'assets/images/logo_dark.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.air_rounded,
                                      size: 80,
                                      color: Theme.of(context).colorScheme.primary.withOpacity( 0.3),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No AHU units available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // AHU selection
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity( 0.1),
                              ),
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select AHU Unit',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: selectedAhuId,
                                  decoration: InputDecoration(
                                    labelText: 'AHU Unit',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Image.asset(
                                        isDark 
                                            ? 'assets/images/logo_light.png'
                                            : 'assets/images/logo_dark.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.air);
                                        },
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  items: ahus.map((ahu) {
                                    return DropdownMenuItem(
                                      value: ahu.id,
                                      child: Text(ahu.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAhuId = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (selectedAhuId != null) ...[
                            // WiFi Provisioning
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withOpacity( 0.1),
                                ),
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.wifi, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'WiFi Provisioning',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Primary WiFi
                                  Text(
                                    'Primary WiFi (Pi Hotspot)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _primarySsidController,
                                    decoration: InputDecoration(
                                      labelText: 'SSID',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.wifi),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _primaryPassController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.lock),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Secondary WiFi
                                  Text(
                                    'Secondary WiFi (Hospital Network)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _secondarySsidController,
                                    decoration: InputDecoration(
                                      labelText: 'SSID',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.wifi),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _secondaryPassController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.lock),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _provisionWifi(provider),
                                      icon: const Icon(Icons.send_rounded),
                                      label: const Text('Provision WiFi'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Broker Provisioning
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withOpacity( 0.1),
                                ),
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.dns, color: AppTheme.success),
                                      const SizedBox(width: 8),
                                      Text(
                                        'MQTT Broker Settings',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _brokerHostController,
                                    decoration: InputDecoration(
                                      labelText: 'Broker Host',
                                      hintText: 'e.g., 10.42.0.1 or mqtt-broker.local',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.computer),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _brokerPortController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Port',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.numbers),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _provisionBroker(provider),
                                      icon: const Icon(Icons.send_rounded),
                                      label: const Text('Provision Broker'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Motor Timing Configuration Section
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity( 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer, color: AppTheme.info),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Motor Timing Configuration',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // M1 Start Run Time
                                TextField(
                                  controller: _m1StartController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Motor-1 Start Run Time (seconds)',
                                    hintText: '10',
                                    helperText: 'Duration Motor-1 runs after system starts',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.play_circle),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // M1 Post Run Time
                                TextField(
                                  controller: _m1PostController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Motor-1 Post Run Time (seconds)',
                                    hintText: '10',
                                    helperText: 'Duration Motor-1 runs during shutdown filter',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.stop_circle),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // M2 Interval
                                TextField(
                                  controller: _m2IntervalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Motor-2 Interval (seconds)',
                                    hintText: '30',
                                    helperText: 'Time between Motor-2 drain cycles',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.refresh),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // M2 Run Time
                                TextField(
                                  controller: _m2RunController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Motor-2 Run Time (seconds)',
                                    hintText: '10',
                                    helperText: 'Duration Motor-2 runs each cycle',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.schedule),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // M2 Delay
                                TextField(
                                  controller: _m2DelayController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Motor-2 Delay After M1 (seconds)',
                                    hintText: '5',
                                    helperText: 'Delay before Motor-2 starts after Motor-1 stops',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.hourglass_empty),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Buttons row
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _resetMotorTimings,
                                        icon: const Icon(Icons.restore),
                                        label: const Text('Reset to Defaults'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _provisionMotorTimings(provider),
                                        icon: const Icon(Icons.send_rounded),
                                        label: const Text('Save Timings'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.info,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _resetMotorTimings() {
    setState(() {
      _m1StartController.text = '10';
      _m1PostController.text = '10';
      _m2IntervalController.text = '30';
      _m2RunController.text = '10';
      _m2DelayController.text = '5';
    });
    _showSuccess('Motor timings reset to defaults');
  }
  
  void _provisionMotorTimings(AppProvider provider) {
    if (selectedAhuId == null) {
      _showError('Please select an AHU first');
      return;
    }

    final m1Start = int.tryParse(_m1StartController.text);
    final m1Post = int.tryParse(_m1PostController.text);
    final m2Interval = int.tryParse(_m2IntervalController.text);
    final m2Run = int.tryParse(_m2RunController.text);
    final m2Delay = int.tryParse(_m2DelayController.text);

    if (m1Start == null || m1Post == null || m2Interval == null || 
        m2Run == null || m2Delay == null) {
      _showError('Please enter valid numbers for all timing fields');
      return;
    }

    if (m1Start < 1 || m1Start > 999 || m1Post < 1 || m1Post > 999 ||
        m2Interval < 1 || m2Interval > 999 || m2Run < 1 || m2Run > 999 ||
        m2Delay < 1 || m2Delay > 999) {
      _showError('Timing values must be between 1 and 999 seconds');
      return;
    }

    provider.provisionMotorTimings(
      selectedAhuId!,
      m1Start: m1Start,
      m1Post: m1Post,
      m2Interval: m2Interval,
      m2Run: m2Run,
      m2Delay: m2Delay,
    );

    _showSuccess('Motor timings sent to AHU. Check ESP32 logs for confirmation.');
  }

  void _provisionWifi(AppProvider provider) {
    if (selectedAhuId == null) return;

    final primarySsid = _primarySsidController.text.trim();
    final primaryPass = _primaryPassController.text.trim();
    final secondarySsid = _secondarySsidController.text.trim();
    final secondaryPass = _secondaryPassController.text.trim();

    if (primarySsid.isEmpty && secondarySsid.isEmpty) {
      _showError('Please enter at least one WiFi network');
      return;
    }

    provider.provisionWifi(
      selectedAhuId!,
      primarySsid: primarySsid.isNotEmpty ? primarySsid : null,
      primaryPass: primaryPass.isNotEmpty ? primaryPass : null,
      secondarySsid: secondarySsid.isNotEmpty ? secondarySsid : null,
      secondaryPass: secondaryPass.isNotEmpty ? secondaryPass : null,
    );

    _showSuccess('WiFi credentials sent to AHU');
  }

  void _provisionBroker(AppProvider provider) {
    if (selectedAhuId == null) return;

    final host = _brokerHostController.text.trim();
    final portStr = _brokerPortController.text.trim();

    if (host.isEmpty) {
      _showError('Please enter broker host');
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port <= 0 || port > 65535) {
      _showError('Please enter a valid port number');
      return;
    }

    provider.provisionBroker(selectedAhuId!, host, port);

    _showSuccess('Broker settings sent to AHU');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Helper function to exit the application and return to desktop
void _exitApplication(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        title: const Text('Exit to Desktop'),
        content: const Text(
          'This will close the AHU Dashboard and return to the Raspberry Pi desktop.\n\n'
          'The dashboard will automatically restart on next boot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exitToDesktop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Exit to Desktop'),
          ),
        ],
      );
    },
  );
}

/// Exit kiosk mode and return to Raspberry Pi desktop
void _exitToDesktop() async {
  if (Platform.isLinux) {
    // Try to run the exit script first
    try {
      final scriptPath = '/home/almed/Documents/almed_ahu/ahu_dashboard/rpi_kiosk_setup/exit_to_desktop.sh';
      final result = await Process.run('bash', [scriptPath]);
      if (result.exitCode != 0) {
        // Script failed, just exit the app
        exit(0);
      }
    } catch (e) {
      // If script doesn't exist or fails, just exit normally
      exit(0);
    }
  } else if (Platform.isWindows || Platform.isMacOS) {
    exit(0);
  } else {
    SystemNavigator.pop();
  }
}

