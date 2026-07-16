import 'dart:io';

import 'package:flutter/material.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 90, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No Internet Connection",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please check your internet and try again.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _checking
                  ? null
                  : () async {
                final navigator = Navigator.of(context);

                setState(() => _checking = true);

                try {
                  final result = await InternetAddress.lookup("google.com");

                  if (!context.mounted) return;

                  if (result.isNotEmpty) {
                    navigator.pop();
                  } else {
                    setState(() => _checking = false);
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  setState(() => _checking = false);
                }
              },
              child: _checking
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}