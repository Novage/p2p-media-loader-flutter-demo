import 'dart:convert';
import 'package:demo/demo/vidstack_player_webview/p2p_stats.dart';
import 'package:webview_flutter/webview_flutter.dart';

class P2PStatsManager {
  final Function(P2PStats)? onStatsUpdate;
  final P2PStats _stats = P2PStats();

  P2PStatsManager({this.onStatsUpdate});

  void onPeerConnected(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToAdd = msgData['peerId'] as String?;
    if (peerToAdd == null || peerToAdd.isEmpty) return;

    _stats.activePeers.add(peerToAdd);
    _updateStats();
  }

  void onPeerClose(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToRemove = msgData['peerId'] as String?;
    if (peerToRemove == null || peerToRemove.isEmpty) return;

    _stats.activePeers.remove(peerToRemove);
    _updateStats();
  }

  void onChunkDownloaded(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final downloadedBytes = (msgData['downloadedBytes'] as num?)?.toDouble();
    final downloadSource = msgData['downloadSource'] as String?;
    if (downloadedBytes == null || downloadSource == null) return;

    if (downloadSource == 'http') {
      _stats.totalHttpDownloaded += convertToMiB(downloadedBytes);
    } else if (downloadSource == 'p2p') {
      _stats.totalP2PDownloaded += convertToMiB(downloadedBytes);
    }
    _updateStats();
  }

  void onChunkUploaded(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final uploadedBytes = (msgData['uploadedBytes'] as num?)?.toDouble();
    if (uploadedBytes == null) return;

    _stats.totalP2PUploaded += convertToMiB(uploadedBytes);
    _updateStats();
  }

  void _updateStats() {
    onStatsUpdate?.call(_stats);
  }

  double convertToMiB(double bytes) => bytes / 1024 / 1024;
}
