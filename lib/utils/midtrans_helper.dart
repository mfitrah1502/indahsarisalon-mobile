import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransHelper {
  static Future<String?> createTransaction({
    required String orderId,
    required int grossAmount,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final serverKey = dotenv.env['MIDTRANS_SERVER_KEY'];
    final isProduction = dotenv.env['MIDTRANS_IS_PRODUCTION'] == 'true';

    if (serverKey == null || serverKey.isEmpty) {
      throw Exception("Midtrans Server Key is not set in .env");
    }

    final url = isProduction
        ? 'https://app.midtrans.com/snap/v1/transactions'
        : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

    final authHeader = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({
        "transaction_details": {
          "order_id": orderId,
          "gross_amount": grossAmount,
        },
        "customer_details": {
          "first_name": customerName,
          "email": customerEmail ?? "customer@example.com",
          "phone": customerPhone ?? "08123456789",
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['redirect_url']; // The URL to open in WebView / Browser
    } else {
      throw Exception('Failed to create Midtrans transaction: ${response.statusCode} - ${response.body}');
    }
  }
}
