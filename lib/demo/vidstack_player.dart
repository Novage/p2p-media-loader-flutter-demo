import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'p2p_stats.dart';

const double kAspectRatio = 16 / 9;
const String kVidstackPlayerHtml = 'assets/vidstack_player.html';

double convertToMiB(double bytes) => bytes / 1024 / 1024;

class VidstackPlayer extends StatefulWidget {
  const VidstackPlayer({super.key});

  @override
  State<VidstackPlayer> createState() => _VidstackPlayerState();
}

class _VidstackPlayerState extends State<VidstackPlayer>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  List<String> activePeers = [];
  double totalHttpDownloaded = 0;
  double totalP2PDownloaded = 0;
  double totalP2PUploaded = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebViewController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _destroyP2P();
    super.dispose();
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

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("onPeerConnect",
          onMessageReceived: _onPeerConnected)
      ..addJavaScriptChannel("onPeerClose", onMessageReceived: _onPeerClose)
      ..addJavaScriptChannel("onChunkDownloaded",
          onMessageReceived: _onChunkDownloaded)
      ..addJavaScriptChannel("onChunkUploaded",
          onMessageReceived: _onChunkUploaded)
      ..loadFlutterAsset(kVidstackPlayerHtml);

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateP2PState(false);
    } else if (state == AppLifecycleState.paused) {
      _updateP2PState(true);
    }
  }

  void _onChunkUploaded(JavaScriptMessage msg) {
    if (!mounted) return;
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final uploadedBytes = (msgData['uploadedBytes'] as num?)?.toDouble();
    if (uploadedBytes == null) return;

    setState(() => totalP2PUploaded += convertToMiB(uploadedBytes));
  }

  void _onPeerConnected(JavaScriptMessage msg) {
    if (!mounted) return;
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToAdd = msgData['peerId'] as String?;
    if (peerToAdd == null || peerToAdd.isEmpty) return;

    setState(() => activePeers.add(peerToAdd));
  }

  void _onPeerClose(JavaScriptMessage msg) {
    if (!mounted) return;
    final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
    final peerToRemove = msgData['peerId'] as String?;
    if (peerToRemove == null || peerToRemove.isEmpty) return;

    setState(() => activePeers.remove(peerToRemove));
  }

  void _onChunkDownloaded(JavaScriptMessage msg) {
    if (!mounted) return;
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

  void _updateP2PState(bool isP2PDisabled) {
    _controller.runJavaScript("window.updateP2PState($isP2PDisabled)");
  }

  void _destroyP2P() {
    _controller.runJavaScript("window.destroyP2P()");
  }

  @override
  Widget build(BuildContext context) {
    final double webViewWidth = MediaQuery.of(context).size.width;
    final double webViewHeight = webViewWidth / kAspectRatio;

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
              child: WebViewWidget(controller: _controller),
            ),
            const SizedBox(height: 20),
            P2PStats(
              totalHttpDownloaded: totalHttpDownloaded,
              totalP2PDownloaded: totalP2PDownloaded,
              totalP2PUploaded: totalP2PUploaded,
              activePeers: activePeers,
            ),
          ],
        ),
      ),
    );
  }
}
