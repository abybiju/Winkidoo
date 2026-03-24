import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class PullRefreshWrapper extends StatelessWidget {
  const PullRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryOrange,
      backgroundColor: brightness == Brightness.dark
          ? AppTheme.surface2
          : AppTheme.lightSurface,
      strokeWidth: 2.5,
      displacement: 40,
      child: child,
    );
  }
}
