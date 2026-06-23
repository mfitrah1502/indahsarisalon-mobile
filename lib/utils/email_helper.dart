import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailHelper {
  /// Sends an OTP email to the user using Gmail SMTP.
  /// Throws an exception if `SMTP_EMAIL` or `SMTP_PASSWORD` is not set.
  static Future<bool> sendOTPEmail(String toEmail, String otpCode) async {
    final email = dotenv.env['SMTP_EMAIL'];
    final password = dotenv.env['SMTP_PASSWORD'];

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      throw Exception('SMTP credentials (SMTP_EMAIL, SMTP_PASSWORD) are not set in .env');
    }

    // Configure Gmail SMTP Server
    final smtpServer = gmail(email, password);

    // Create the email message
    final message = Message()
      ..from = Address(email, 'Indah Sari Salon')
      ..recipients.add(toEmail)
      ..subject = 'Kode OTP Pemulihan Akun - Indah Sari Salon'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #B53D7C; margin: 0; font-size: 24px; font-weight: bold;">Indah Sari Salon</h2>
            <p style="color: #64748B; margin: 4px 0 0 0; font-size: 14px;">Pemulihan Kata Sandi</p>
          </div>
          
          <div style="line-height: 1.6; color: #0F172A; font-size: 15px;">
            <p>Halo,</p>
            <p>Kami menerima permintaan untuk menyetel ulang kata sandi akun Indah Sari Salon Anda. Silakan gunakan kode OTP di bawah ini untuk memverifikasi identitas Anda:</p>
            
            <div style="text-align: center; margin: 32px 0;">
              <div style="display: inline-block; padding: 16px 32px; background-color: #FDF2F8; border: 2px dashed #D660A1; border-radius: 8px; font-size: 32px; font-weight: bold; color: #B53D7C; letter-spacing: 4px;">
                $otpCode
              </div>
            </div>
            
            <p style="color: #64748B; font-size: 14px; margin-top: 24px;">
              * Kode OTP ini bersifat rahasia dan hanya berlaku selama 10 menit. Jangan bagikan kode ini kepada siapa pun, termasuk staf Indah Sari Salon.
            </p>
            
            <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 32px 0 24px 0;" />
            
            <p style="font-size: 13px; color: #94A3B8; text-align: center; margin: 0;">
              Jika Anda tidak meminta pengaturan ulang kata sandi ini, silakan abaikan email ini dengan aman.
            </p>
          </div>
        </div>
      ''';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      throw Exception('Gagal mengirim email lewat SMTP: $e');
    }
  }
}
