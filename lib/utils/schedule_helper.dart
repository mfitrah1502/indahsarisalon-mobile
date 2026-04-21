import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleHelper {
  /// Mendapatkan list jam yang tersedia (contoh: ["09:00", "09:15", ...])
  /// - [date]: Tanggal booking yang dipilih
  /// - [stylistId]: ID dari stylist
  /// - [totalDuration]: Total durasi semua layanan yang dipilih (dalam menit)
  /// - [shiftStartHour], [shiftEndHour]: Jam operasional/shift (misal: 9 - 18)
  static Future<List<String>> getAvailableTimeSlots({
    required DateTime date,
    required int stylistId,
    required int totalDuration,
    int shiftStartHour = 9,
    int shiftEndHour = 18,
  }) async {
    final supabase = Supabase.instance.client;
    
    // 1. Definisikan jam awal dan akhir dari hari yang dipilih
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateStr = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";

    try {
      // Cek Absensi dulu. Jika stylist libur (off) di hari ini, langsung return kosong.
      final absensi = await supabase
          .from('absensi')
          .select('status')
          .eq('user_id', stylistId)
          .eq('tanggal', dateStr)
          .maybeSingle();

      if (absensi != null && absensi['status'] == 'off') {
        return [];
      }
      // 2. Ambil data booking dari database yang ada di tanggal tersebut untuk stylist yang dipilih
      // catatan: pastikan mengecualikan yang 'dibatalkan'
      final response = await supabase
          .from('bookings')
          .select('''
            reservation_datetime, 
            status,
            booking_details (
              treatment_details ( duration )
            )
          ''')
          .eq('stylist_id', stylistId)
          .neq('status', 'dibatalkan')
          .gte('reservation_datetime', startOfDay.toIso8601String())
          .lte('reservation_datetime', endOfDay.toIso8601String());

      final List<dynamic> bookingsData = response;

      // 3. Ekstrak data start_time dan end_time untuk setiap booking
      List<_TimeRange> existingBookings = [];
      for (var b in bookingsData) {
        if (b['reservation_datetime'] == null) continue;
        
        final dtStr = b['reservation_datetime'] as String;
        final startTime = DateTime.parse(dtStr);
        
        // Hitung total durasi dari booking ini
        int sumDuration = 0;
        final details = b['booking_details'] as List<dynamic>?;
        if (details != null) {
          for (var detail in details) {
            final td = detail['treatment_details'] as Map<String, dynamic>?;
            if (td != null && td['duration'] != null) {
              sumDuration += (td['duration'] as num).toInt();
            }
          }
        }
        
        // Jika karena alasan tertentu durasi 0, kita asumsikan default 30 menit
        if (sumDuration == 0) sumDuration = 30;

        final endTime = startTime.add(Duration(minutes: sumDuration));
        
        existingBookings.add(_TimeRange(start: startTime, end: endTime));
      }

      // 4. Generate slot waktu setiap 15 menit
      List<String> availableSlots = [];
      DateTime slotStart = DateTime(date.year, date.month, date.day, shiftStartHour, 0);
      final shiftEnd = DateTime(date.year, date.month, date.day, shiftEndHour, 0);

      while (slotStart.isBefore(shiftEnd)) {
        final slotEnd = slotStart.add(Duration(minutes: totalDuration));

        // Jika (jam mulai + durasi treatment) melebihi jam tutup, maka slot tidak valid
        if (slotEnd.isAfter(shiftEnd)) {
          // Karena slotEnd terus bertambah, semua iterasi selanjutnya pasti akan melebihi shift
          break;
        }

        // Pastikan slot tidak bentrok dengan jadwal lain
        bool isConflict = false;
        for (var b in existingBookings) {
          // Kondisi Overlap Logis: (StartA < EndB) AND (EndA > StartB)
          if (slotStart.isBefore(b.end) && slotEnd.isAfter(b.start)) {
            isConflict = true;
            break;
          }
        }

        // Jangan tampilkan waktu yang sudah lewat jika harinya adalah hari ini
        final now = DateTime.now();
        if (slotStart.isBefore(now)) {
           isConflict = true; 
        }

        // Jika valid, tambahkan ke result
        if (!isConflict) {
          final hour = slotStart.hour.toString().padLeft(2, '0');
          final minute = slotStart.minute.toString().padLeft(2, '0');
          availableSlots.add("$hour:$minute");
        }

        // Increment 15 menit untuk slot selanjutnya
        slotStart = slotStart.add(const Duration(minutes: 15));
      }

      return availableSlots;
    } catch (e) {
      debugPrint("Error fetching schedules: \$e");
      // Fallback aman jika terjadi error
      return []; 
    }
  }
}

class _TimeRange {
  final DateTime start;
  final DateTime end;

  _TimeRange({required this.start, required this.end});
}
