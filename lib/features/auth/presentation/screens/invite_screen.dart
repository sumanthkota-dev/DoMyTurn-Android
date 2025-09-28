import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/home_repository.dart';

class InviteScreen extends StatefulWidget {
  final int homeId;
  const InviteScreen({super.key, required this.homeId});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HomeRepository _homeRepo = HomeRepository();

  String? inviteLink;
  Uint8List? qrImage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    final link = await _homeRepo.fetchInviteLink(widget.homeId);
    final qrResponse = await _homeRepo.fetchQrCode(widget.homeId);
    if (qrResponse.statusCode == 200) {
      setState(() {
        inviteLink = link;
        qrImage = qrResponse.data;
        loading = false;
      });
    } else {
      setState(() {
        inviteLink = link;
        loading = false;
      });
    }
  }

  void shareLink() {
    if (inviteLink != null) {
      Share.share("Join my home on DoMyTask using this link:\n$inviteLink");
    }
  }

  void copyToClipboard() {
    if (inviteLink != null) {
      Clipboard.setData(ClipboardData(text: inviteLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invite link copied to clipboard")),
      );
    }
  }

  void shareQrImage() async {
    if (qrImage != null) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr.png');
      await file.writeAsBytes(qrImage!);
      await Share.shareXFiles([XFile(file.path)], text: 'Scan this QR to join my home on DoMyTask!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Others")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Invite Link"),
              Tab(text: "QR Code"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Invite Link Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(inviteLink ?? "No link"),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text("Copy"),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: shareLink,
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // QR Code Tab
                Center(
                  child: qrImage != null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.memory(qrImage!, width: 200),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: shareQrImage,
                        icon: const Icon(Icons.share),
                        label: const Text("Share QR"),
                      ),
                    ],
                  )
                      : const Text("Failed to load QR code"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
