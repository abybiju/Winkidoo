import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/features/play/play_card_stack_state.dart';
import 'package:winkidoo/features/play/widgets/peek_strip.dart';

class PlayCardStack extends ConsumerWidget {
  const PlayCardStack({
    super.key,
    required this.cardWidgets,
  });

  final List<Widget> cardWidgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(activePlayCardProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          for (int i = 0; i < cardWidgets.length; i++) ...[
            if (i > 0)
              Transform.translate(
                offset: Offset(0, i == activeIndex || i - 1 == activeIndex ? 0 : -4),
                child: const SizedBox(height: 6),
              ),
            _PlayStackEntry(
              index: i,
              isActive: i == activeIndex,
              meta: playCardMetas[i],
              onTap: () {
                ref.read(activePlayCardProvider.notifier).state = i;
              },
              child: cardWidgets[i],
            ),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _PlayStackEntry extends StatelessWidget {
  const _PlayStackEntry({
    required this.index,
    required this.isActive,
    required this.meta,
    required this.onTap,
    required this.child,
  });

  final int index;
  final bool isActive;
  final PlayCardMeta meta;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: isActive
          ? KeyedSubtree(
              key: ValueKey('expanded_$index'),
              child: child,
            )
          : KeyedSubtree(
              key: ValueKey('peek_$index'),
              child: PeekStrip(
                meta: meta,
                onTap: onTap,
              ),
            ),
    );
  }
}
