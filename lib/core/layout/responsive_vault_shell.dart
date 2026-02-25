import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/vault/vault_list_screen.dart';

/// Wraps vault in responsive layout: desktop web = two-panel (sidebar + detail), mobile = single panel with bottom nav + FAB.
class ResponsiveVaultShell extends ConsumerStatefulWidget {
  const ResponsiveVaultShell({super.key});

  @override
  ConsumerState<ResponsiveVaultShell> createState() =>
      _ResponsiveVaultShellState();
}

class _ResponsiveVaultShellState extends ConsumerState<ResponsiveVaultShell> {
  final GlobalKey<NavigatorState> _detailNavigatorKey = GlobalKey<NavigatorState>();

  bool get _isDesktopWeb {
    if (!kIsWeb) return false;
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppConstants.desktopBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isDesktopWeb) {
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: VaultListScreen(
                  desktopDetailNavigatorKey: _detailNavigatorKey,
                  isDesktopSidebar: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: Navigator(
                  key: _detailNavigatorKey,
                  initialRoute: '/',
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    builder: (_) => const _DetailPlaceholder(),
                  ),
                ),
              ),
            ],
          );
        }
        return VaultListScreen(
          showBottomNav: true,
          isDesktopSidebar: false,
        );
      },
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientColors(Theme.of(context).brightness),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 64,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a surprise from the vault or create one',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
