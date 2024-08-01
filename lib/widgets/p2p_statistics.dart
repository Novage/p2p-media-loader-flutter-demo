import 'package:flutter/material.dart';
import 'info_card.dart';

class P2PStatistics extends StatelessWidget {
  final double totalHttpDownloaded;
  final double totalP2PDownloaded;
  final double totalP2PUploaded;
  final List<String> activePeers;

  const P2PStatistics({
    super.key,
    required this.totalHttpDownloaded,
    required this.totalP2PDownloaded,
    required this.totalP2PUploaded,
    required this.activePeers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          InfoCard(
            title: 'Downloaded through HTTP',
            content: '${totalHttpDownloaded.toStringAsFixed(2)} MiB',
            icon: Icons.download,
          ),
          const SizedBox(height: 10),
          InfoCard(
            title: 'Downloaded through P2P',
            content: '${totalP2PDownloaded.toStringAsFixed(2)} MiB',
            icon: Icons.cloud_download,
          ),
          const SizedBox(height: 10),
          InfoCard(
            title: 'Uploaded through P2P',
            content: '${totalP2PUploaded.toStringAsFixed(2)} MiB',
            icon: Icons.cloud_upload,
          ),
          const SizedBox(height: 10),
          InfoCard(
            title: 'Active Peers',
            content: activePeers.length.toString(),
            icon: Icons.group,
          ),
        ],
      ),
    );
  }
}
