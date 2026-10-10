import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/or_lights_provider.dart';
import '../providers/or_session_provider.dart';
import '../theme/app_theme.dart';

class SurgeonPanelCard extends StatelessWidget {
  final bool isSmallScreen;

  const SurgeonPanelCard({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = isSmallScreen ? 380.0 : 420.0;

    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(isSmallScreen: isSmallScreen),
            SizedBox(height: isSmallScreen ? 12 : 16),
            const _Clock(),
            SizedBox(height: isSmallScreen ? 10 : 14),
            const _TimerActions(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            const _StampList(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _LightsGrid(isSmallScreen: isSmallScreen),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isSmallScreen;

  const _Header({required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 40 : 44,
          height: isSmallScreen ? 40 : 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Surgeon panel',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: isSmallScreen ? 20 : 22,
                ),
              ),
              Text(
                'Local to this display',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit lights',
          onPressed: () => _editLights(context),
          icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  void _editLights(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _LightsEditorDialog(),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Selector<OrSessionProvider, ({String text, bool running, bool stopped})>(
      selector: (_, p) => (
        text: OrSessionProvider.formatElapsed(p.elapsed),
        running: p.isRunning,
        stopped: p.isStopped,
      ),
      builder: (context, data, _) {
        final color = data.running
            ? AppTheme.success
            : data.stopped
                ? const Color(0xFFF59E0B)
                : theme.colorScheme.primary;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Text(
                data.text,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                data.running
                    ? 'Operation running'
                    : data.stopped
                        ? 'Stopped'
                        : 'Ready',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerActions extends StatelessWidget {
  const _TimerActions();

  @override
  Widget build(BuildContext context) {
    return Consumer<OrSessionProvider>(
      builder: (context, session, _) {
        return Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: session.isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: session.isRunning
                    ? 'Stop'
                    : session.hasSession
                        ? 'Resume'
                        : 'Start',
                color: session.isRunning
                    ? const Color(0xFFF59E0B)
                    : AppTheme.success,
                onTap: () =>
                    session.isRunning ? session.stop() : session.start(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.flag_rounded,
                label: 'Log time',
                color: const Color(0xFF3B82F6),
                onTap: session.hasSession ? session.logTime : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.refresh_rounded,
                label: 'Clear',
                color: AppTheme.error,
                onTap: session.hasSession ? session.clear : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: color.withOpacity(enabled ? 0.12 : 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: enabled ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampList extends StatelessWidget {
  const _StampList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<OrSessionProvider>(
      builder: (context, session, _) {
        if (session.stamps.isEmpty) {
          return Text(
            'Log time to keep the last 5 stamps. Oldest drops first.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < session.stamps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      OrSessionProvider.formatElapsed(session.stamps[i].elapsed),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _wall(session.stamps[i].at),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _wall(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    final s = at.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _LightsGrid extends StatelessWidget {
  final bool isSmallScreen;

  const _LightsGrid({required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrLightsProvider>(
      builder: (context, lights, _) {
        if (lights.lights.isEmpty) {
          return TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _LightsEditorDialog(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a light'),
          );
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isSmallScreen ? 2.1 : 2.3,
          children: [
            for (final light in lights.lights)
              _LightTile(
                light: light,
                onTap: () => lights.toggle(light.id),
                onLongPress: () => _rename(context, lights, light),
              ),
          ],
        );
      },
    );
  }

  Future<void> _rename(
    BuildContext context,
    OrLightsProvider lights,
    OrLight light,
  ) async {
    final controller = TextEditingController(text: light.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename light'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await lights.rename(light.id, name);
  }
}

class _LightTile extends StatelessWidget {
  final OrLight light;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LightTile({
    required this.light,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = light.on ? const Color(0xFFF59E0B) : Colors.grey;
    return Material(
      color: color.withOpacity(light.on ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                light.on
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      light.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    Text(
                      light.on ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightsEditorDialog extends StatefulWidget {
  const _LightsEditorDialog();

  @override
  State<_LightsEditorDialog> createState() => _LightsEditorDialogState();
}

class _LightsEditorDialogState extends State<_LightsEditorDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrLightsProvider>(
      builder: (context, lights, _) {
        return AlertDialog(
          title: const Text('Lights'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Up to ${lights.maxLights} lights. Each uses a ROCK 4B GPIO. '
                  '${lights.gpioAvailable ? 'GPIO ready.' : 'GPIO not found — buttons still work on screen.'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 12),
                for (final light in lights.lights)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(light.name),
                    subtitle: Text(light.pin?.label ?? 'Pin ${light.headerPin}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => lights.removeLight(light.id),
                    ),
                  ),
                if (lights.canAdd) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'New light name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
            if (lights.canAdd)
              FilledButton(
                onPressed: () async {
                  final ok = await lights.addLight(_name.text);
                  if (ok) _name.clear();
                },
                child: const Text('Add'),
              ),
          ],
        );
      },
    );
  }
}
