import 'package:flutter/material.dart';

/// Small "AWS" pill shown while a card is fed from the cloud instead of
/// local MQTT. Fades in and out as the source switches.
class AwsSourcePill extends StatelessWidget {
  final bool visible;
  final bool isSmall;

  const AwsSourcePill({super.key, required this.visible, this.isSmall = false});

  static const Color _color = Color(0xFFFF9900);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('local'))
          : Tooltip(
              key: const ValueKey('aws'),
              message: 'No local MQTT. Live data from AWS.',
              child: Container(
                margin: EdgeInsets.only(right: isSmall ? 6 : 8),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 8 : 10,
                  vertical: isSmall ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(isSmall ? 10 : 14),
                  border: Border.all(color: _color.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_rounded,
                      size: isSmall ? 14 : 16,
                      color: _color,
                    ),
                    SizedBox(width: isSmall ? 4 : 5),
                    Text(
                      'AWS',
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
