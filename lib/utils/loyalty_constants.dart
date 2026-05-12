/// WhatsApp group links and loyalty tier configuration for Indah Sari Salon
class LoyaltyConstants {
  // ── WhatsApp group links per tier ──────────────────────────────────────────
  static const String silverGroupLink   = 'https://chat.whatsapp.com/Jifm43U6J4d9ltRPak0wVd?mode=gi_t';
  static const String goldGroupLink     = 'https://chat.whatsapp.com/J7QpkhenO5kJpfumE7a6ag?mode=gi_t';
  static const String platinumGroupLink = 'https://chat.whatsapp.com/Kv5F6HrNlugBpc5Py0kCGH?mode=gi_t';
  static const String communityGroupLink = 'https://chat.whatsapp.com/Klzg8cq9767Iolv1Dl7d5T?mode=gi_t';

  /// Returns the WhatsApp group link for a given tier name.
  static String groupLinkForTier(String tier) {
    switch (tier) {
      case 'Platinum': return platinumGroupLink;
      case 'Gold':     return goldGroupLink;
      case 'Silver':   return silverGroupLink;
      default:         return silverGroupLink; // fallback
    }
  }

  // ── Spend thresholds ───────────────────────────────────────────────────────
  static const int silverMinSpend   = 1000000;
  static const int goldMinSpend     = 2000000;
  static const int platinumMinSpend = 3000000;
}
