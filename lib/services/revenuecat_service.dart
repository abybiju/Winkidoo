import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';

/// Wraps the RevenueCat Purchases SDK.
///
/// Call [init] once at startup (after Supabase init).
/// Call [configureUser] whenever the auth user changes.
/// Listen to [entitlementStream] for real-time entitlement updates.
class RevenueCatService {
  RevenueCatService._();

  static bool _initialized = false;

  static final _entitlementController = StreamController<bool>.broadcast();

  /// Stream that emits `true` when the user has an active Wink+ entitlement.
  static Stream<bool> get entitlementStream => _entitlementController.stream;

  /// Whether the SDK was initialized successfully.
  static bool get isInitialized => _initialized;

  /// Initialize RevenueCat. Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;

    final apiKey = AppConstants.revenueCatApiKey;
    if (apiKey.isEmpty) {
      debugPrint('RevenueCatService: No API key — skipping init. '
          'Pass --dart-define=REVENUECAT_API_KEY=... to enable IAP.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);

      // Listen for CustomerInfo changes (purchase, renewal, expiry).
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      _initialized = true;
      debugPrint('RevenueCatService: initialized');
    } catch (e, st) {
      debugPrint('RevenueCatService.init error: $e');
      debugPrint('$st');
    }
  }

  /// Set the RevenueCat app user ID to the Supabase auth user ID.
  /// Call on login; RevenueCat merges anonymous → identified automatically.
  static Future<void> configureUser(String userId) async {
    if (!_initialized) return;

    try {
      final info = await Purchases.logIn(userId);
      _emitEntitlement(info.customerInfo);
      debugPrint('RevenueCatService: logged in user $userId');
    } catch (e) {
      debugPrint('RevenueCatService.configureUser error: $e');
    }
  }

  /// Call on logout — resets to anonymous user.
  static Future<void> resetUser() async {
    if (!_initialized) return;

    try {
      await Purchases.logOut();
      _entitlementController.add(false);
      debugPrint('RevenueCatService: logged out');
    } catch (e) {
      debugPrint('RevenueCatService.resetUser error: $e');
    }
  }

  /// Fetch current offerings (products + pricing).
  static Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCatService.getOfferings error: $e');
      return null;
    }
  }

  /// Purchase a package. Returns the updated CustomerInfo on success, null on cancel/error.
  static Future<CustomerInfo?> purchase(Package package) async {
    if (!_initialized) return null;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final info = result.customerInfo;
      _emitEntitlement(info);
      await _syncToSupabase(info);
      return info;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCatService: purchase cancelled by user');
        return null;
      }
      debugPrint('RevenueCatService.purchase error: $errorCode — $e');
      rethrow;
    }
  }

  /// Restore purchases (e.g. after reinstall or device switch).
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) return null;

    try {
      final info = await Purchases.restorePurchases();
      _emitEntitlement(info);
      await _syncToSupabase(info);
      return info;
    } catch (e) {
      debugPrint('RevenueCatService.restorePurchases error: $e');
      rethrow;
    }
  }

  /// Check current entitlement without hitting the network (uses cache).
  static Future<bool> hasWinkPlus() async {
    if (!_initialized) return false;

    try {
      final info = await Purchases.getCustomerInfo();
      return _isWinkPlusActive(info);
    } catch (e) {
      debugPrint('RevenueCatService.hasWinkPlus error: $e');
      return false;
    }
  }

  // ── Private helpers ──

  static void _onCustomerInfoUpdated(CustomerInfo info) {
    _emitEntitlement(info);
    _syncToSupabase(info);
  }

  static void _emitEntitlement(CustomerInfo info) {
    _entitlementController.add(_isWinkPlusActive(info));
  }

  static bool _isWinkPlusActive(CustomerInfo info) {
    final entitlement =
        info.entitlements.all[AppConstants.rcEntitlementWinkPlus];
    return entitlement?.isActive == true;
  }

  /// Write the entitlement expiration date to couples.wink_plus_until so the
  /// server (RLS, Edge Functions) and the partner's device both see the status.
  static Future<void> _syncToSupabase(CustomerInfo info) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final entitlement =
          info.entitlements.all[AppConstants.rcEntitlementWinkPlus];
      final expiresAt = entitlement?.isActive == true
          ? entitlement!.expirationDate
          : null;

      // Find the couple row for this user.
      final rows = await client
          .from('couples')
          .select('id')
          .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
          .limit(1);

      if (rows.isEmpty) return;
      final coupleId = rows.first['id'] as String;

      await client.from('couples').update({
        'wink_plus_until': expiresAt,
      }).eq('id', coupleId);

      debugPrint('RevenueCatService: synced wink_plus_until=$expiresAt');
    } catch (e) {
      debugPrint('RevenueCatService._syncToSupabase error: $e');
    }
  }
}
