import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_restart.dart';
import '../services/app_version.dart';
import '../services/dashboard_update_service.dart';

/// Shows live update progress, then offers to restart into the new version.
class UpdateProgressDialog extends StatefulWidget {
  const UpdateProgressDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpdateProgressDialog(),
    );
  }

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  final _service = DashboardUpdateService();
  StreamSubscription<UpdateProgress>? _sub;
  UpdateProgress _progress =
      const UpdateProgress(UpdatePhase.checking, 'Checking for updates...');
  bool _restarting = false;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
  );

  @override
  void initState() {
    super.initState();
    _sub = _service.start().listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _restart() async {
    setState(() => _restarting = true);
    final relaunched = await AppRestart.restart();
    if (!relaunched) {
      await _service.requestRestart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _progress;
    final busy = !p.isFinal;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderIcon(phase: p.phase),
              const SizedBox(height: 12),
              Text(
                _title(p.phase),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              if (busy || p.phase == UpdatePhase.ready) ...[
                const SizedBox(height: 18),
                _ProgressBar(percent: p.percent, gradient: _gradient),
                const SizedBox(height: 14),
                _Steps(phase: p.phase),
              ],
              if (p.phase == UpdatePhase.ready) ...[
                const SizedBox(height: 16),
                _VersionChange(
                  from: AppVersion.label,
                  to: p.newVersion,
                ),
              ],
              const SizedBox(height: 18),
              ..._actions(context, p),
            ],
          ),
        ),
      ),
    );
  }

  String _title(UpdatePhase phase) {
    switch (phase) {
      case UpdatePhase.checking:
        return 'Checking for updates';
      case UpdatePhase.upToDate:
        return 'Up to date';
      case UpdatePhase.downloading:
        return 'Downloading update';
      case UpdatePhase.building:
        return 'Installing update';
      case UpdatePhase.ready:
        return 'Update ready';
      case UpdatePhase.error:
        return 'Update failed';
    }
  }

  List<Widget> _actions(BuildContext context, UpdateProgress p) {
    if (p.phase == UpdatePhase.ready) {
      return [
        _GradientButton(
          label: _restarting ? 'Restarting...' : 'Restart now',
          icon: Icons.restart_alt_rounded,
          loading: _restarting,
          gradient: _gradient,
          onPressed: _restart,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _restarting ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
      ];
    }
    if (p.isFinal) {
      return [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ];
    }
    return [
      Text(
        'Keep the display on. The dashboard keeps running while it updates.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hide'),
      ),
    ];
  }
}

class _HeaderIcon extends StatelessWidget {
  final UpdatePhase phase;

  const _HeaderIcon({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (phase) {
      UpdatePhase.upToDate => (Icons.verified_rounded, const Color(0xFF10B981)),
      UpdatePhase.ready => (Icons.rocket_launch_rounded, const Color(0xFF10B981)),
      UpdatePhase.error => (Icons.error_outline_rounded, const Color(0xFFEF4444)),
      _ => (Icons.system_update_alt_rounded, const Color(0xFF3B82F6)),
    };
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(icon),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int? percent;
  final Gradient gradient;

  const _ProgressBar({required this.percent, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = percent == null ? null : (percent!.clamp(0, 100) / 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: value == null
                ? LinearProgressIndicator(
                    backgroundColor: theme.dividerColor.withOpacity(0.15),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween(end: value),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, v, _) => Stack(
                      children: [
                        Container(color: theme.dividerColor.withOpacity(0.15)),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: gradient),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 6),
          Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  final UpdatePhase phase;

  const _Steps({required this.phase});

  @override
  Widget build(BuildContext context) {
    const order = [
      UpdatePhase.checking,
      UpdatePhase.downloading,
      UpdatePhase.building,
      UpdatePhase.ready,
    ];
    const labels = ['Check', 'Download', 'Install', 'Ready'];
    final current = order.indexOf(phase);
    return Row(
      children: [
        for (var i = 0; i < order.length; i++)
          Expanded(
            child: _Step(
              label: labels[i],
              done: i < current || phase == UpdatePhase.ready,
              active: i == current && phase != UpdatePhase.ready,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _Step({required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = done
        ? const Color(0xFF10B981)
        : active
            ? theme.colorScheme.primary
            : theme.dividerColor.withOpacity(0.4);
    return Column(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: active
              ? CircularProgressIndicator(strokeWidth: 2.5, color: color)
              : Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: color,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _VersionChange extends StatelessWidget {
  final String from;
  final String? to;

  const _VersionChange({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              from,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, size: 18),
          ),
          Flexible(
            child: Text(
              to ?? 'new version',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final Gradient gradient;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

/// Shown once on the first launch after an update.
class UpdatedNoticeDialog extends StatelessWidget {
  final String from;

  const UpdatedNoticeDialog({super.key, required this.from});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderIcon(phase: UpdatePhase.ready),
              const SizedBox(height: 12),
              Text(
                'Dashboard updated',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are now running the latest version.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              _VersionChange(from: from, to: AppVersion.label),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Great'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
