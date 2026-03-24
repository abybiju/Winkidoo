import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkSwitch extends StatefulWidget {
  const WinkSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<WinkSwitch> createState() => _WinkSwitchState();
}

class _WinkSwitchState extends State<WinkSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.microDuration,
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant WinkSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final trackColor = Color.lerp(
            brightness == Brightness.dark
                ? AppTheme.glassFillHover
                : const Color(0xFFE0D8ED),
            AppTheme.primaryOrange,
            t,
          )!;
          final thumbOffset = Tween<double>(begin: 2, end: 22).transform(t);

          return Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: trackColor,
              border: Border.all(
                color: t > 0.5
                    ? AppTheme.primaryOrange.withValues(alpha: 0.40)
                    : (brightness == Brightness.dark
                        ? AppTheme.glassBorder
                        : const Color(0x33A093C0)),
              ),
              boxShadow: t > 0.5
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.20),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: thumbOffset,
                  top: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                        if (t > 0.5)
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.30),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
