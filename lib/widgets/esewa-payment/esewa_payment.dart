import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/payment_config.dart';
import '../../data/model/car_model.dart';


class EsewaPaymentWidget {

  CarModel? selectedCar;
  double fare = 0;

  void processEsewaSDKPayment({
    required BuildContext context,
    required Function(String, String) onConfirm,
    required Function(String) onError,
    }) {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
            environment: Environment.test,
            clientId: PaymentConfig.clientId,
            secretId: PaymentConfig.secretKey
        ),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: selectedCar!.model,
          productPrice: fare.toStringAsFixed(0),
          callbackUrl: '',
        ),
        onPaymentSuccess: (data) => onConfirm("paid", "eSewa"),
        onPaymentFailure: (data) => onError("Payment Failed"),
        onPaymentCancellation: (data) => debugPrint("Cancelled"),
      );
    } catch (e) {
      debugPrint("eSewa Error: $e");
    }
  }

  Future<void> payWithEsewaWeb(double amount,Function(String) onError) async {
    final pid = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse("https://uat.esewa.com.np/epay/main?amt=${amount.toStringAsFixed(0)}&pdc=0&psc=0&txAmt=0&tAmt=${amount.toStringAsFixed(0)}&pid=$pid&scd=EPAYTEST&su=https://your-success-url.com&fu=https://your-failure-url.com");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      onError('Could not open eSewa portal');
    }
  }
}