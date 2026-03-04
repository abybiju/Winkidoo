import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/vault/vault_list_screen.dart';

/// Wraps vault in responsive layout: desktop web = two-panel (sidebar + detail), mobile = single panel with bottom nav + FAB.
/// When [isInsideShell] is true (e.g. from go_router 4-tab shell), the shell's bottom nav is shown; this flag only
/// controls the vault's own duplicate bar so we do not show two navs. Deep routes (Create, Battle) are outside the shell.
class ResponsiveVaultShell extends ConsumerStatefulWidget {
  const ResponsiveVaultShell({super.key, this.isInsideShell = false});

  final bool isInsideShell;

  @override
  ConsumerState<ResponsiveVaultShell> createState() =>
      _ResponsiveVaultShellState();
}

class _ResponsiveVaultShellState extends ConsumerState<ResponsiveVaultShell> {
  final GlobalKey<NavigatorState> _detailNavigatorKey =
      GlobalKey<NavigatorState>();

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
          showBottomNav: !widget.isInsideShell,
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
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientColors(brightness),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.12, -0.7),
                    radius: 1.0,
                    colors: AppTheme.vaultHeroGlow(brightness),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.vaultHeroGradient(brightness),
                    ),
                    border:
                        Border.all(color: AppTheme.premiumBorder30(brightness)),
                    boxShadow: AppTheme.premiumElevation(brightness),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppTheme.vaultDramaVignette.withValues(
                                    alpha: brightness == Brightness.dark
                                        ? 0.62
                                        : 0.34,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_open_rounded,
                              size: 36,
                              color: Color(0xFFF5C76B),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Choose a surprise to open',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pick an item from the left vault list or create a new one.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.74),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
