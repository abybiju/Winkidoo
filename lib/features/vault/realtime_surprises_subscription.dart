import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/couple.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/realtime_service.dart';

/// Listens to Supabase Realtime for new/updated surprises and invalidates list.
/// On INSERT by partner, sets [partnerAddedSurpriseAtProvider] so vault can show snackbar.
class RealtimeSurprisesSubscription extends ConsumerStatefulWidget {
  const RealtimeSurprisesSubscription({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<RealtimeSurprisesSubscription> createState() =>
      _RealtimeSurprisesSubscriptionState();
}

class _RealtimeSurprisesSubscriptionState
    extends ConsumerState<RealtimeSurprisesSubscription> {
  RealtimeService? _realtime;
  String? _subscribedCoupleId;

  @override
  void dispose() {
    _realtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Couple?>>(coupleProvider, (prev, next) {
      next.whenData((couple) {
        final id = couple?.id;
        if (id != null && id != _subscribedCoupleId) {
          _subscribedCoupleId = id;
          _realtime?.dispose();
          final client = ref.read(supabaseClientProvider);
          final currentUserId = ref.read(currentUserProvider)?.id;
          _realtime = RealtimeService(client);
          _realtime!.subscribe(id, (payload) {
            ref.invalidate(surprisesListProvider);
            if (payload.eventType == PostgresChangeEvent.insert) {
              final creatorId = payload.newRecord?['creator_id'] as String?;
              if (creatorId != null && creatorId != currentUserId) {
                ref.read(partnerAddedSurpriseAtProvider.notifier).state =
                    DateTime.now();
              }
            }
          });
        } else if (id == null) {
          _subscribedCoupleId = null;
          _realtime?.dispose();
          _realtime = null;
        }
      });
    });

    return widget.child;
  }
}
