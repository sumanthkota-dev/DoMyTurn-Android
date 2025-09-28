import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/home_repository.dart'; // ✅ Make sure it's correct

final logger = Logger(printer: PrettyPrinter());

class QrJoinHomeScreen extends StatefulWidget {
  const QrJoinHomeScreen({super.key});

  @override
  State<QrJoinHomeScreen> createState() => _QrJoinHomeScreenState();
}

class _QrJoinHomeScreenState extends State<QrJoinHomeScreen> {
  final HomeRepository _homeRepository = HomeRepository(); // ✅ Use repo, not Dio
  bool _isProcessing = false;

  void _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final rawValue = capture.barcodes.first.rawValue;
    logger.i("💡 Raw Value : $rawValue");

    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map || decoded['type'] != 'join_home') {
        _showDialog('Invalid QR code type.');
        return;
      }

      final String? inviteCode = decoded['inviteCode'];
      if (inviteCode == null) {
        _showDialog('Missing invite code.');
        return;
      }

      // ✅ Call HomeRepository method
      final success = await _homeRepository.joinHome(inviteCode);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Joined home successfully")),
        );
        context.go('/dashboard'); // Or your desired screen
      } else {
        _showDialog('Failed to join home. Please check invite code.');
      }
    } catch (e, stack) {
      logger.e("❌ Join Home Error", error: e, stackTrace: stack);
      _showDialog('Error joining home: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Home'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double scanBoxSize = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR to Join Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal,
                  ),
                  onDetect: _onQrDetected,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Align the QR code within the square",
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
