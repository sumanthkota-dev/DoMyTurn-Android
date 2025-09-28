import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/home_repository.dart';

class QRCodeViewScreen extends StatefulWidget {
  final int homeId;
  const QRCodeViewScreen({super.key, required this.homeId});

  @override
  State<QRCodeViewScreen> createState() => _QRCodeViewScreenState();
}

class _QRCodeViewScreenState extends State<QRCodeViewScreen> {
  final HomeRepository _homeRepo = HomeRepository();
  Uint8List? qrBytes;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadQRCode();
  }

  Future<void> loadQRCode() async {
    final response = await _homeRepo.fetchQrCode(widget.homeId);
    if (response.statusCode == 200) {
      setState(() {
        qrBytes = response.data;
        loading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load QR code')),
      );
      setState(() => loading = false);
    }
  }

  Future<void> shareQRCode() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/qr.png');
    await file.writeAsBytes(qrBytes!);

    await Share.shareXFiles([XFile(file.path)], text: 'Scan this QR to join my home!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Home QR")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(qrBytes!, width: 250, height: 250),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: shareQRCode,
              icon: const Icon(Icons.share),
              label: const Text("Share QR Code"),
            ),
          ],
        ),
      ),
    );
  }
}
