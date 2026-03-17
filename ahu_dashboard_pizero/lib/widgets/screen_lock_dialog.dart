import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Touch-friendly passcode dialog for unlocking the screen
class ScreenUnlockDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool Function(String passcode) onVerify;
  
  const ScreenUnlockDialog({
    super.key,
    this.title = 'Unlock Screen',
    this.subtitle = 'Enter 6-digit passcode',
    required this.onVerify,
  });

  @override
  State<ScreenUnlockDialog> createState() => _ScreenUnlockDialogState();
}

class _ScreenUnlockDialogState extends State<ScreenUnlockDialog> with SingleTickerProviderStateMixin {
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
    if (_enteredPasscode.length < 6) {
      setState(() {
        _enteredPasscode += number;
        _isError = false;
      });

      if (_enteredPasscode.length == 6) {
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
    if (widget.onVerify(_enteredPasscode)) {
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
        width: 420,
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
                _Title(title: widget.title, subtitle: widget.subtitle, isDark: isDark),
                const SizedBox(height: 24),
                _PasscodeDots(
                  enteredLength: _enteredPasscode.length,
                  isError: _isError,
                  shakeAnimation: _shakeAnimation,
                  shakeController: _shakeController,
                  isDark: isDark,
                  dotCount: 6,
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
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.lock_open_rounded, size: 32, color: Colors.white),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  
  const _Title({required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
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
  final int dotCount;
  
  const _PasscodeDots({
    required this.enteredLength,
    required this.isError,
    required this.shakeAnimation,
    required this.shakeController,
    required this.isDark,
    this.dotCount = 6,
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
        children: List.generate(dotCount, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError
                  ? AppTheme.error
                  : index < enteredLength
                      ? const Color(0xFFF59E0B)
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              border: Border.all(
                color: isError ? AppTheme.error : const Color(0xFFF59E0B).withOpacity(0.5),
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
        const SizedBox(height: 10),
        _KeypadRow(numbers: ['4', '5', '6'], onPressed: onNumberPressed, isDark: isDark),
        const SizedBox(height: 10),
        _KeypadRow(numbers: ['7', '8', '9'], onPressed: onNumberPressed, isDark: isDark),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 70, height: 70),
            const SizedBox(width: 10),
            _KeypadButton(number: '0', onPressed: onNumberPressed, isDark: isDark),
            const SizedBox(width: 10),
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
          padding: EdgeInsets.only(left: n != numbers.first ? 10 : 0),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x4DF59E0B),
                Color(0x66F59E0B),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFFD97706),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(isDark ? 0.15 : 0.08),
                baseColor.withOpacity(isDark ? 0.2 : 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
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
            size: 26,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
