/// Menyimpan data sesi pengguna yang sedang login.
/// Diisi saat login berhasil, dikosongkan saat logout.
class AppSession {
  static int? userId;
  static String? userName;
  static String? userRole;

  static void clear() {
    userId = null;
    userName = null;
    userRole = null;
  }
}
