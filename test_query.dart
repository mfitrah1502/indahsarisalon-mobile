import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://acwubkiohkqaedhwrvpr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjd3Via2lvaGtxYWVkaHdydnByIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjE2MDY3NywiZXhwIjoyMDg3NzM2Njc3fQ.KJvcrsIAJGdp4zP9BcTOI9gmdWkE6bVeovZBh5otg70');
  
  final res = await supabase
      .from('bookings')
      .select('id, stylist_id, stylist:users!bookings_stylist_id_fkey(name)')
      .order('id', ascending: false)
      .limit(3);
      
  print(res);
}
