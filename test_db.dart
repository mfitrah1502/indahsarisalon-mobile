import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'missing';
  final supabaseKey = Platform.environment['SUPABASE_KEY'] ?? 'missing';
  
  if (supabaseUrl == 'missing') {
    print("Cannot test DB, missing env vars");
    return;
  }
}
