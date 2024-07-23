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
          onMessageReceived: _onChunkDownloaded);

    var platform = controller.platform;

    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  void _onPeerConnected(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToAdd = msgData['peerId'] as String?;

    if (peerToAdd == null) return;

    setState(() {
      activePeers.add(peerToAdd);
    });
  }

  void _onPeerClose(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToRemove = msgData['peerId'] as String?;

    if (peerToRemove == null) return;

    setState(() {
      activePeers.remove(peerToRemove);
    });
  }

  void _onChunkDownloaded(JavaScriptMessage msg) {
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final loadedBytes = msgData['bytesLength'] as double?;
    final downloadSource = msgData['downloadSource'] as String?;

    if (loadedBytes == null || downloadSource == null) return;

    setState(() {
      if (downloadSource == 'http') {
        totalHttpDownloaded += convertToMiB(loadedBytes);
      } else if (downloadSource == 'p2p') {
        totalP2PDownloaded += convertToMiB(loadedBytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double webViewWidth = MediaQuery.of(context).size.width;
    final double webViewHeight = webViewWidth / aspectRatio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Component'),
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
            _buildInfoText(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Peers: ${activePeers.join(', ')}'),
        Text(
            'Downloaded through HTTP: ${totalHttpDownloaded.toStringAsFixed(2)} MiB'),
        Text(
            'Downloaded through P2P: ${totalP2PDownloaded.toStringAsFixed(2)} MiB'),
      ],
    );
  }
}
