import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

double convertToMiB(double bytes) {
  return bytes / 1024 / 1024;
}

class VidstackPlayer extends StatefulWidget {
  const VidstackPlayer({super.key});

  @override
  State<VidstackPlayer> createState() => _VidstackPlayerState();
}

class _VidstackPlayerState extends State<VidstackPlayer> {
  late final WebViewController controller;
  final double aspectRatio = 16 / 9;
  List<String> activePeers = [];
  double totalHttpDownloaded = 0;
  double totalP2PDownloaded = 0;
  double totalP2PUploaded = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    controller.loadFlutterAsset('assets/vidstack_player.html');
  }

  void _initializeWebViewController() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("onPeerConnected",
          onMessageReceived: _onPeerConnected)
      ..addJavaScriptChannel("onPeerClose", onMessageReceived: _onPeerClose)
      ..addJavaScriptChannel("onChunkDownloaded",
          onMessageReceived: _onChunkDownloaded)
      ..addJavaScriptChannel("onChunkUploaded",
          onMessageReceived: _onChunkUploaded);

    var platform = controller.platform;

    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  void _onChunkUploaded(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final uploadedBytes = (msgData['uploadedBytes'] as num?)?.toDouble();

    if (uploadedBytes == null) return;

    setState(() {
      totalP2PUploaded += convertToMiB(uploadedBytes);
    });
  }

  void _onPeerConnected(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToAdd = msgData['peerId'] as String?;

    if (peerToAdd == null || peerToAdd.isEmpty) return;

    setState(() {
      activePeers.add(peerToAdd);
    });
  }

  void _onPeerClose(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToRemove = msgData['peerId'] as String?;

    if (peerToRemove == null || peerToRemove.isEmpty) return;

    setState(() {
      activePeers.remove(peerToRemove);
    });
  }

  void _onChunkDownloaded(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final downloadedBytes = (msgData['downloadedBytes'] as num?)?.toDouble();
    final downloadSource = msgData['downloadSource'] as String?;

    if (downloadedBytes == null || downloadSource == null) return;

    setState(() {
      if (downloadSource == 'http') {
        totalHttpDownloaded += convertToMiB(downloadedBytes);
      } else if (downloadSource == 'p2p') {
        totalP2PDownloaded += convertToMiB(downloadedBytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double webViewWidth = MediaQuery.of(context).size.width;
    final double webViewHeight = webViewWidth / aspectRatio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vidstack Player'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: webViewWidth,
              height: webViewHeight,
              child: WebViewWidget(controller: controller),
            ),
            const SizedBox(height: 20),
            _buildInfoCards(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildCard(
            title: 'Downloaded through HTTP',
            content: '${totalHttpDownloaded.toStringAsFixed(2)} MiB',
            icon: Icons.download,
          ),
          const SizedBox(height: 10),
          _buildCard(
            title: 'Downloaded through P2P',
            content: '${totalP2PDownloaded.toStringAsFixed(2)} MiB',
            icon: Icons.cloud_download,
          ),
          const SizedBox(height: 10),
          _buildCard(
            title: 'Uploaded through P2P',
            content: '${totalP2PUploaded.toStringAsFixed(2)} MiB',
            icon: Icons.cloud_upload,
          ),
          const SizedBox(height: 10),
          _buildCard(
            title: 'Active Peers',
            content: activePeers.length.toString(),
            icon: Icons.group,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required String content,
      required IconData icon}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }
}
