import 'package:flutter/material.dart';
import '../p2p_webview_demo/vidstack_player_webview.dart';
import '../widgets/p2p_statistics.dart';

class VidstackPlayerScreen extends StatefulWidget {
  const VidstackPlayerScreen({super.key});

  @override
  State<VidstackPlayerScreen> createState() => _VidstackPlayerScreenState();
}

class _VidstackPlayerScreenState extends State<VidstackPlayerScreen> {
  final Set<String> _activePeers = {};
  double _totalHttpDownloaded = 0;
  double _totalP2PDownloaded = 0;
  double _totalP2PUploaded = 0;

  void _updateHttpDownloadStats(double httpDownloaded) {
    setState(() {
      _totalHttpDownloaded += httpDownloaded;
    });
  }

  void _updateP2PDownloadStats(double p2pDownloaded) {
    setState(() {
      _totalP2PDownloaded += p2pDownloaded;
    });
  }

  void _updateP2PUploadStats(double p2pUploaded) {
    setState(() {
      _totalP2PUploaded += p2pUploaded;
    });
  }

  void _addActivePeer(String peerId) {
    setState(() {
      _activePeers.add(peerId);
    });
  }

  void _removeActivePeer(String peerId) {
    setState(() {
      _activePeers.remove(peerId);
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
              onChunkDownloadedByHttp: _updateHttpDownloadStats,
              onChunkDownloadedByP2P: _updateP2PDownloadStats,
              onChunkUploaded: _updateP2PUploadStats,
              onPeerConnect: _addActivePeer,
              onPeerClose: _removeActivePeer,
            ),
            const SizedBox(height: 20),
            const Text(
              'P2P Media Loader Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            P2PStatistics(
              totalHttpDownloaded: _totalHttpDownloaded,
              totalP2PDownloaded: _totalP2PDownloaded,
              totalP2PUploaded: _totalP2PUploaded,
              activePeers: _activePeers.toList(),
            ),
          ],
        ),
      ),
    );
  }
}
