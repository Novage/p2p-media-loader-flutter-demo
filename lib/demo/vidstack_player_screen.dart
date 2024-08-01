import 'package:demo/demo/p2p_statistics.dart';
import 'package:flutter/material.dart';
import 'vidstack_player_webview/p2p_stats.dart';
import 'vidstack_player_webview/vidstack_player_webview.dart';

class VidstackPlayerScreen extends StatefulWidget {
  const VidstackPlayerScreen({super.key});

  @override
  State<VidstackPlayerScreen> createState() => _VidstackPlayerScreenState();
}

class _VidstackPlayerScreenState extends State<VidstackPlayerScreen> {
  P2PStats _latestStats = P2PStats();

  void _updateStats(P2PStats stats) {
    setState(() {
      _latestStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vidstack Player'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            VidstackWebView(
              assetPath: 'assets/vidstack_player.html',
              onStatsUpdate: _updateStats,
            ),
            const SizedBox(height: 20),
            P2PStatistics(
              totalHttpDownloaded: _latestStats.totalHttpDownloaded,
              totalP2PDownloaded: _latestStats.totalP2PDownloaded,
              totalP2PUploaded: _latestStats.totalP2PUploaded,
              activePeers: _latestStats.activePeers,
            ),
          ],
        ),
      ),
    );
  }
}
