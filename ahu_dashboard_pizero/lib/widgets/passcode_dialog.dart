import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Touch-friendly passcode dialog for Admin access
class PasscodeDialog extends StatefulWidget {
  const PasscodeDialog({super.key});

  @override
  State<PasscodeDialog> createState() => _PasscodeDialogState();
}

class _PasscodeDialogState extends State<PasscodeDialog> with SingleTickerProviderStateMixin {
  static const String _adminPasscode = '1234';
  String _enteredPasscode = '';
  bool _isError = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_enteredPasscode.length < 4) {
      setState(() {
        _enteredPasscode += number;
        _isError = false;
      });

      if (_enteredPasscode.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _verifyPasscode);
      }
    }
  }

  void _onBackspace() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() {
        _enteredPasscode = _enteredPasscode.substring(0, _enteredPasscode.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPasscode() {
    if (_enteredPasscode == _adminPasscode) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isError = true);
      _shakeController.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _enteredPasscode = '';
              _isError = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                : [Colors.white, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LockIcon(),
                const SizedBox(height: 20),
                _Title(isDark: isDark),
                const SizedBox(height: 24),
                _PasscodeDots(
                  enteredLength: _enteredPasscode.length,
                  isError: _isError,
                  shakeAnimation: _shakeAnimation,
                  shakeController: _shakeController,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                _NumericKeypad(
                  onNumberPressed: _onNumberPressed,
                  onBackspace: _onBackspace,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.lightPrimary, AppTheme.lightPrimary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightPrimary.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.lock_rounded, size: 32, color: Colors.white),
    );
  }
}

class _Title extends StatelessWidget {
  final bool isDark;
  
  const _Title({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Admin Access',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter 4-digit passcode',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _PasscodeDots extends StatelessWidget {
  final int enteredLength;
  final bool isError;
  final Animation<double> shakeAnimation;
  final AnimationController shakeController;
  final bool isDark;
  
  const _PasscodeDots({
    required this.enteredLength,
    required this.isError,
    required this.shakeAnimation,
    required this.shakeController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            shakeAnimation.value * (shakeController.status == AnimationStatus.forward ? 1 : -1),
            0,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError
                  ? AppTheme.error
                  : index < enteredLength
                      ? AppTheme.lightPrimary
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              border: Border.all(
                color: isError ? AppTheme.error : AppTheme.lightPrimary.withOpacity(0.5),
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final bool isDark;

  const _NumericKeypad({
    required this.onNumberPressed,
    required this.onBackspace,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _KeypadRow(numbers: ['1', '2', '3'], onPressed: onNumberPressed, isDark: isDark),
        const SizedBox(height: 12),
        _KeypadRow(numbers: ['4', '5', '6'], onPressed: onNumberPressed, isDark: isDark),
        const SizedBox(height: 12),
        _KeypadRow(numbers: ['7', '8', '9'], onPressed: onNumberPressed, isDark: isDark),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80),
            const SizedBox(width: 12),
            _KeypadButton(number: '0', onPressed: onNumberPressed, isDark: isDark),
            const SizedBox(width: 12),
            _BackspaceButton(onPressed: onBackspace, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _KeypadRow extends StatelessWidget {
  final List<String> numbers;
  final Function(String) onPressed;
  final bool isDark;
  
  const _KeypadRow({
    required this.numbers,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((n) {
        return Padding(
          padding: EdgeInsets.only(left: n != numbers.first ? 12 : 0),
          child: _KeypadButton(number: n, onPressed: onPressed, isDark: isDark),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String number;
  final Function(String) onPressed;
  final bool isDark;

  const _KeypadButton({
    required this.number,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPressed(number),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightPrimary.withOpacity(0.3),
                AppTheme.lightPrimary.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightPrimary.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightPrimary.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  
  const _BackspaceButton({required this.onPressed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white : Colors.black;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(isDark ? 0.15 : 0.08),
                baseColor.withOpacity(isDark ? 0.2 : 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: baseColor.withOpacity(isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.backspace_rounded,
            size: 28,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
