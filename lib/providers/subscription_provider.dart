import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:winkidoo/services/revenuecat_service.dart';

/// Whether the current user has an active Wink+ entitlement via RevenueCat.
/// Updates in real time when purchases/renewals/expirations occur.
final rcEntitlementProvider = StreamProvider<bool>((ref) {
  // Seed with a check of the current state, then listen for changes.
  final controller = StreamController<bool>();

  RevenueCatService.hasWinkPlus().then((active) {
    if (!controller.isClosed) controller.add(active);
  });

  final sub = RevenueCatService.entitlementStream.listen((active) {
    if (!controller.isClosed) controller.add(active);
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Current RevenueCat offerings (products + pricing).
/// Fetched once; call ref.invalidate to refresh.
final rcOfferingsProvider = FutureProvider<Offerings?>((ref) async {
  if (!RevenueCatService.isInitialized) return null;
  return RevenueCatService.getOfferings();
});

/// Purchase state for the paywall UI.
enum PurchaseStatus { idle, purchasing, restoring, success, error }

class PurchaseState {
  const PurchaseState({
    this.status = PurchaseStatus.idle,
    this.errorMessage,
  });

  final PurchaseStatus status;
  final String? errorMessage;

  PurchaseState copyWith({PurchaseStatus? status, String? errorMessage}) {
    return PurchaseState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier() : super(const PurchaseState());

  Future<bool> purchase(Package package) async {
    state = const PurchaseState(status: PurchaseStatus.purchasing);
    try {
      final info = await RevenueCatService.purchase(package);
      if (info != null) {
        state = const PurchaseState(status: PurchaseStatus.success);
        return true;
      }
      // User cancelled.
      state = const PurchaseState(status: PurchaseStatus.idle);
      return false;
    } catch (e) {
      debugPrint('PurchaseNotifier.purchase error: $e');
      state = PurchaseState(
        status: PurchaseStatus.error,
        errorMessage: 'Purchase failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> restore() async {
    state = const PurchaseState(status: PurchaseStatus.restoring);
    try {
      await RevenueCatService.restorePurchases();
      state = const PurchaseState(status: PurchaseStatus.success);
      return true;
    } catch (e) {
      debugPrint('PurchaseNotifier.restore error: $e');
      state = PurchaseState(
        status: PurchaseStatus.error,
        errorMessage: 'Restore failed. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const PurchaseState();
  }
}

final purchaseNotifierProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) => PurchaseNotifier(),
);
