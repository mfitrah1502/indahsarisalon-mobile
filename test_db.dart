// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'missing';
  final supabaseKey = Platform.environment['SUPABASE_KEY'] ?? 'missing';
  
  if (supabaseUrl == 'missing') {
    print("Cannot test DB, missing env vars");
    return;
  }
}
