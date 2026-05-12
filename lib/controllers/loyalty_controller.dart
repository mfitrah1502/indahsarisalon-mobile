import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_session.dart';

class LoyaltyController {
  static final _supabase = Supabase.instance.client;

  // ─── Tier helpers ────────────────────────────────────────────────────────────

  static String tierFromSpend(num spend) {
    if (spend >= 3000000) return 'Platinum';
    if (spend >= 2000000) return 'Gold';
    if (spend >= 1000000) return 'Silver';
    return 'None';
  }

  static int tierRank(String tier) {
    switch (tier) {
      case 'Platinum': return 3;
      case 'Gold':     return 2;
      case 'Silver':   return 1;
      default:         return 0;
    }
  }

  // ─── Called when a booking is marked "berhasil" ──────────────────────────────
  // Looks up the customer in `users` by phone or email, then updates their spend
  // and tier.  Returns { 'upgraded': true, 'new_tier': '...' } when tier goes up.
  static Future<Map<String, dynamic>?> processBookingCompletion({
    required num amount,
    String? customerPhone,
    String? customerEmail,
    int? userId,
  }) async {
    try {
      // 1. Find the customer row
      Map<String, dynamic>? userRow;

      if (userId != null) {
        final res = await _supabase
            .from('users')
            .select('id, total_spend, membership_tier, last_transaction_at')
            .eq('id', userId)
            .maybeSingle();
        userRow = res;
      }

      if (userRow == null && (customerPhone?.isNotEmpty ?? false)) {
        final res = await _supabase
            .from('users')
            .select('id, total_spend, membership_tier, last_transaction_at')
            .eq('phone', customerPhone!)
            .maybeSingle();
        userRow = res;
      }

      if (userRow == null && (customerEmail?.isNotEmpty ?? false)) {
        final res = await _supabase
            .from('users')
            .select('id, total_spend, membership_tier, last_transaction_at')
            .eq('email', customerEmail!)
            .maybeSingle();
        userRow = res;
      }

      if (userRow == null) return null; // Customer not in users table

      final int custId       = userRow['id'] as int;
      final num currentSpend = (userRow['total_spend'] as num?) ?? 0;
      final String oldTier   = userRow['membership_tier'] as String? ?? 'None';

      final num newSpend  = currentSpend + amount;
      final String newTier = tierFromSpend(newSpend);

      final bool upgraded = tierRank(newTier) > tierRank(oldTier);

      await _supabase.from('users').update({
        'total_spend':         newSpend,
        'membership_tier':     newTier,
        'last_transaction_at': DateTime.now().toIso8601String(),
      }).eq('id', custId);

      // Update session if it's the current user
      if (userId == AppSession.userId || custId == AppSession.userId) {
        AppSession.userTier = newTier;
      }

      if (upgraded) {
        return {'upgraded': true, 'new_tier': newTier};
      }
      return null;
    } catch (e) {
      // Don't crash the booking flow if loyalty update fails
      return null;
    }
  }

  // ─── Retention & expiry checks (run on app start) ─────────────────────────
  // Resets tier if no transaction in 1 year; expires Colour Circle after 2 years.
  static Future<void> checkRetention(int userId) async {
    try {
      final userRes = await _supabase
          .from('users')
          .select('last_transaction_at, membership_tier, is_colour_circle, colour_circle_expired_at')
          .eq('id', userId)
          .maybeSingle();

      if (userRes == null) return;

      final lastTx = userRes['last_transaction_at'] != null
          ? DateTime.parse(userRes['last_transaction_at'] as String)
          : null;

      final updates = <String, dynamic>{};

      // 1-year inactivity → remove tier
      if (lastTx != null) {
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        if (lastTx.isBefore(oneYearAgo)) {
          updates['membership_tier'] = 'None';
          updates['total_spend']     = 0;
        }
      }

      // Colour Circle expiry
      if (userRes['is_colour_circle'] == true && userRes['colour_circle_expired_at'] != null) {
        final expiry = DateTime.parse(userRes['colour_circle_expired_at'] as String);
        if (DateTime.now().isAfter(expiry)) {
          updates['is_colour_circle'] = false;
        }
      }

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', userId);
        if (userId == AppSession.userId) {
          if (updates.containsKey('membership_tier')) {
            AppSession.userTier = updates['membership_tier'];
          }
        }
      }
    } catch (e) {
      // Silent — don't block the UI
    }
  }
}
