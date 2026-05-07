import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Load .env manually
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? url;
  String? key;
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1];
    if (line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1];
  }

  if (url == null || key == null) {
    print("Error: Could not find Supabase credentials in .env");
    return;
  }

  final supabase = SupabaseClient(url, key);

  print("Cleaning up promos...");

  try {
    // 1. Delete all from promos
    await supabase.from('promos').delete().neq('id', 0); // Delete all
    print("Deleted all from 'promos' table.");

    // 2. Find treatment IDs that are promos
    final promoTreatments = await supabase.from('treatments').select('id').eq('is_promo', true);
    final List<int> ids = (promoTreatments as List).map((e) => e['id'] as int).toList();

    if (ids.isNotEmpty) {
      // 3. Delete from treatment_details
      await supabase.from('treatment_details').delete().inFilter('treatment_id', ids);
      print("Deleted related treatment details.");

      // 4. Delete from treatments
      await supabase.from('treatments').delete().inFilter('id', ids);
      print("Deleted promo treatments.");
    }

    print("Success: All promos and related treatments have been cleared.");
  } catch (e) {
    print("Error during cleanup: $e");
  }

  exit(0);
}
