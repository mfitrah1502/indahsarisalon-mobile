import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

void main() {
  test('Fix missing notifications for null users', () async {
    await dotenv.load(fileName: ".env");
    
    final supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_ANON_KEY']!,
    );

    print('Connected to Supabase. Fetching bookings...');

    final bookings = await supabase.from('bookings').select('id, user_id, reservation_datetime').eq('id', 178);

    for (final booking in bookings) {
      final bookingId = booking['id'];
      
      String formattedDt = booking['reservation_datetime'];
      try {
        final dt = DateTime.parse(formattedDt).toLocal();
        final date = DateFormat('d MMMM yyyy', 'en').format(dt);
        final time = DateFormat('HH:mm').format(dt);
        formattedDt = "$date at $time WIB";
      } catch (_) {
        if (formattedDt.length >= 16) {
          formattedDt = formattedDt.substring(0, 16).replaceAll('T', ' ');
        }
      }

      try {
        await supabase.from('notifikasi').insert({
          'user_id': null, // allowing null
          'title': 'Booking Success',
          'message': 'Booking for schedule $formattedDt has been successfully created.',
          'booking_id': bookingId,
          'is_read': false,
        });
        print('Successfully inserted notification for booking $bookingId');
      } catch (e) {
        print('Failed to insert for booking $bookingId: $e');
      }
    }
  });
}
