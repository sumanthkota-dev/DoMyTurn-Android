import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          if (_scanned) return; // Prevent multiple triggers
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;

          if (code != null) {
            setState(() => _scanned = true);

            // Example: show result in a snackbar and pop
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Scanned: $code')),
            );

            // Optional: Navigate or process result
            // Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
