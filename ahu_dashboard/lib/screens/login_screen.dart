import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/passcode_dialog.dart';
import 'dashboard_screen.dart';

/// Modern login screen optimized for 7-inch Pi display (1024x600)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650; // Pi display is 600px height
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _LoginBackground(isDark: isDark),
          
          // Theme toggle - smaller for Pi display
          Positioned(
            top: isSmallScreen ? 8 : 48,
            right: isSmallScreen ? 12 : 24,
            child: const _ThemeToggle(),
          ),
          
          // Content - optimized for 1024x600
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 32,
                  vertical: isSmallScreen ? 12 : 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Company Logo - smaller for Pi
                    _LogoWidget(isDark: isDark, isSmallScreen: isSmallScreen),
                    SizedBox(height: isSmallScreen ? 16 : 32),
                    
                    // Title - smaller for Pi
                    Text(
                      'AHU Control',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: isSmallScreen ? 24 : 32,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    Text(
                      'Hospital Air Handling System',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 64),

                    // Role cards - side by side on Pi display for better fit
                    if (isSmallScreen)
                      Row(
                        children: [
                          Expanded(
                            child: _CompactRoleCard(
                              role: UserRole.hospital,
                              icon: Icons.local_hospital_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CompactRoleCard(
                              role: UserRole.admin,
                              icon: Icons.shield_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: const [
                          _ModernRoleCard(
                            role: UserRole.hospital,
                            icon: Icons.local_hospital_rounded,
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                          ),
                          SizedBox(height: 20),
                          _ModernRoleCard(
                            role: UserRole.admin,
                            icon: Icons.shield_rounded,
                            gradient: LinearGradient(
                              colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                            ),
                          ),
                        ],
                      ),
                    
                    SizedBox(height: isSmallScreen ? 16 : 48),
                    Text(
                      'v1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: isSmallScreen ? 10 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  final bool isDark;
  
  const _LoginBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF334155),
                ]
              : [
                  Colors.white,
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final bool isDark;
  final bool isSmallScreen;
  
  const _LogoWidget({required this.isDark, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isSmallScreen ? 120 : 200),
      child: Image.asset(
        isDark 
            ? 'assets/images/logo_light.png'
            : 'assets/images/logo_dark.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackLogo(isDark: isDark, isSmallScreen: isSmallScreen);
        },
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final bool isDark;
  final bool isSmallScreen;
  
  const _FallbackLogo({required this.isDark, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final size = isSmallScreen ? 70.0 : 120.0;
    final iconSize = isSmallScreen ? 35.0 : 60.0;
    
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.lightPrimary,
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
          ),
          child: Icon(
            Icons.air,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 16),
        Text(
          'ALMED',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: isSmallScreen ? 24 : 36,
            fontWeight: FontWeight.w300,
            letterSpacing: isSmallScreen ? 4 : 6,
          ),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;
    
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDarkMode, _) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            iconSize: isSmallScreen ? 20 : 24,
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 32 : 48,
              minHeight: isSmallScreen ? 32 : 48,
            ),
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
        );
      },
    );
  }
}

/// Compact role card for 7-inch Pi display (side by side layout)
class _CompactRoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final Gradient gradient;

  const _CompactRoleCard({
    required this.role,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withOpacity(0.1);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectRole(context, role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              // Text
              Text(
                role.displayName,
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                role.description,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, UserRole role) async {
    if (role == UserRole.admin) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PasscodeDialog(),
      );
      
      if (result != true) return;
    }
    
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LoadingDialog(),
      );
    }

    provider.setUserRole(role);
    provider.loadDefaultAhus();
    
    // Start MQTT connection but don't wait - it will auto-reconnect in background
    // This prevents UI lag on startup
    provider.initializeMqtt();

    if (context.mounted) {
      Navigator.of(context).pop();
      
      // Always navigate to dashboard - MQTT will connect/reconnect in background
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }
}

class _ModernRoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final Gradient gradient;

  const _ModernRoleCard({
    required this.role,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withOpacity(0.1);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectRole(context, role),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, UserRole role) async {
    if (role == UserRole.admin) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PasscodeDialog(),
      );
      
      if (result != true) return;
    }
    
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LoadingDialog(),
      );
    }

    provider.setUserRole(role);
    provider.loadDefaultAhus();
    
    // Start MQTT connection but don't wait - it will auto-reconnect in background
    // This prevents UI lag on startup
    provider.initializeMqtt();

    if (context.mounted) {
      Navigator.of(context).pop();
      
      // Always navigate to dashboard - MQTT will connect/reconnect in background
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;
    
    return Center(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isSmallScreen ? 30 : 40,
              height: isSmallScreen ? 30 : 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Connecting...',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isSmallScreen ? 13 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
