import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../app_session.dart';

class AuthController {
  final _supabase = Supabase.instance.client;

  Future<bool> login(String username, String password) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (data != null) {
        final user = UserModel.fromJson(data);
        bool isPasswordCorrect = false;
        
        try {
          isPasswordCorrect = BCrypt.checkpw(password, user.password);
        } catch (e) {
          // You could throw here or log
        }

        if (isPasswordCorrect) {
          AppSession.userId = user.id;
          AppSession.userName = user.name;
          AppSession.userRole = user.role;
          AppSession.userEmail = user.email;
          return true;
        }
      }
      return false; // Username not found or password incorrect
    } catch (e) {
      throw Exception("Terjadi kesalahan saat memproses login");
    }
  }

  Future<void> logout() async {
    AppSession.clear();
  }
}
