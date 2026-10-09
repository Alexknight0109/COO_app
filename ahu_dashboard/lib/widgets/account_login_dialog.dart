import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'update_progress_dialog.dart';

const _accentGradient = LinearGradient(
  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// ID and password popup. Enter uses the phone login API and keeps the
/// login saved on this Radxa until Logout.
class AccountLoginDialog extends StatefulWidget {
  const AccountLoginDialog({super.key});

  @override
  State<AccountLoginDialog> createState() => _AccountLoginDialogState();
}

class _AccountLoginDialogState extends State<AccountLoginDialog> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _signingIn = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_signingIn) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });
    final result = await context.read<AppProvider>().loginAccount(
          _idController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    if (result.session == null) {
      setState(() {
        _signingIn = false;
        _error = result.error ?? 'Invalid ID or password';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.height < 650;

    return _DialogShell(
      isSmall: isSmall,
      children: [
        _DialogHeader(
          icon: Icons.person_rounded,
          title: 'Account Login',
          subtitle: 'Use the same ID as the phone app',
          isSmall: isSmall,
        ),
        SizedBox(height: isSmall ? 14 : 20),
        TextField(
          controller: _idController,
          enabled: !_signingIn,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(theme, 'ID', Icons.alternate_email_rounded),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_signingIn,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: _fieldDecoration(
            theme,
            'Password',
            Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
          ),
          onSubmitted: (_) => _enter(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _MessageBanner(
                    text: _error!,
                    color: theme.colorScheme.error,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
        ),
        SizedBox(height: isSmall ? 16 : 22),
        _GradientButton(
          label: 'Enter',
          loading: _signingIn,
          onPressed: _enter,
        ),
      ],
    );
  }
}

/// Logged-in account details with Logout.
class AccountInfoDialog extends StatefulWidget {
  const AccountInfoDialog({super.key});

  @override
  State<AccountInfoDialog> createState() => _AccountInfoDialogState();
}

class _AccountInfoDialogState extends State<AccountInfoDialog> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await context.read<AppProvider>().logoutAccount();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.height < 650;
    final session = context.watch<AppProvider>().accountSession;
    if (session == null) return const SizedBox.shrink();
    final count = session.assignedAhuIds.length;

    return _DialogShell(
      isSmall: isSmall,
      children: [
        _DialogHeader(
          icon: Icons.verified_user_rounded,
          title: session.email,
          subtitle: 'Logged in · AWS backup active',
          isSmall: isSmall,
        ),
        SizedBox(height: isSmall ? 14 : 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.hvac_rounded,
              label: '$count AHU${count == 1 ? '' : 's'} assigned',
              color: theme.colorScheme.primary,
            ),
            _InfoChip(
              icon: session.canOperate
                  ? Icons.tune_rounded
                  : Icons.visibility_rounded,
              label: session.canOperate ? 'Operator' : 'Viewer',
              color: session.canOperate
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 12 : 16),
        Text(
          'When local MQTT goes quiet, these AHUs keep updating from AWS. '
          'This login stays saved until you log out.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        SizedBox(height: isSmall ? 16 : 22),
        OutlinedButton.icon(
          onPressed: _loggingOut ? null : _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error.withOpacity(0.6)),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(ThemeData theme, String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: theme.colorScheme.primary.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
  );
}

class _DialogShell extends StatelessWidget {
  final bool isSmall;
  final List<Widget> children;

  const _DialogShell({required this.isSmall, required this.children});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 24 : 40,
        vertical: isSmall ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isSmall ? 18 : 24,
                isSmall ? 18 : 24,
                isSmall ? 18 : 24,
                isSmall ? 16 : 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
            const Positioned(top: 6, right: 6, child: _UpdateIconButton()),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSmall;

  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isSmall ? 48.0 : 56.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: _accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
        SizedBox(height: isSmall ? 10 : 14),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 17 : 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: SizedBox(
            height: 46,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _MessageBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the update progress dialog (check, download, install, restart).
class _UpdateIconButton extends StatelessWidget {
  const _UpdateIconButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Check for update',
      onPressed: () => UpdateProgressDialog.show(context),
      icon: Icon(
        Icons.system_update_alt_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
