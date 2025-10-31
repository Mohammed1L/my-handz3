import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService _instance = StripeService._();
  factory StripeService() => _instance;

  /// Initialize Stripe with publishable key from `K.env`.
  /// Required on app startup before any payment is used.
  static Future<void> init() async {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (publishableKey == null || publishableKey.isEmpty) {
      if (kDebugMode) {
        // No key configured; PaymentSheet will be unavailable.
        // A fallback to Payment Link can still be used.
      }
      return;
    }
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Returns true if payment completed successfully.
  ///
  /// Flow:
  /// 1) If `BACKEND_CREATE_PAYMENT_INTENT_URL` is set in `K.env`, calls it
  ///    with amount (in currency's smallest unit) and currency to create a
  ///    PaymentIntent and retrieve a clientSecret, then presents PaymentSheet.
  /// 2) Else, if `STRIPE_PAYMENT_LINK_URL` is set, launches Stripe-hosted
  ///    checkout in a browser window (web) or via URL launcher (mobile). Caller
  ///    should treat this as an external flow and validate later.
  ///
  /// Expected backend JSON response: { "clientSecret": "pi_..._secret_..." }
  Future<bool> payWithPaymentSheet({
    required int amountMinor,
    required String currency,
    required String description,
    String? customerEmail,
  }) async {
    final backendUrl = dotenv.env['BACKEND_CREATE_PAYMENT_INTENT_URL'];
    if (backendUrl == null || backendUrl.isEmpty) {
      // No backend – signal caller to use payment link fallback
      return false;
    }

    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amountMinor,
        'currency': currency,
        'description': description,
        if (customerEmail != null) 'receipt_email': customerEmail,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Stripe backend error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Invalid backend response: missing clientSecret');
    }

    // Initialize and present the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: dotenv.env['MERCHANT_NAME'] ?? 'Handz',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return true;
  }
}


