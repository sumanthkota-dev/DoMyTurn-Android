import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/home_repository.dart';

class InviteLinkScreen extends StatefulWidget {
  final int homeId;
  const InviteLinkScreen({super.key, required this.homeId});

  @override
  State<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends State<InviteLinkScreen> {
  final HomeRepository _homeRepo = HomeRepository();
  String? inviteLink;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLink();
  }

  Future<void> fetchLink() async {
    final link = await _homeRepo.fetchInviteLink(widget.homeId);
    setState(() {
      inviteLink = link;
      loading = false;
    });
  }

  void shareLink() {
    if (inviteLink != null) {
      Share.share("Join my home on DoMyTask using this link: $inviteLink");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Link")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              inviteLink ?? "Failed to fetch link",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: shareLink,
              icon: const Icon(Icons.share),
              label: const Text("Share Invite Link"),
            ),
          ],
        ),
      ),
    );
  }
}
