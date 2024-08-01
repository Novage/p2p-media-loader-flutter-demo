import 'package:demo/demo/vidstack_player_webview/p2p_stats.dart';
import 'package:demo/demo/vidstack_player_webview/p2p_stats_manager.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class VidstackWebView extends StatefulWidget {
  final String assetPath;
  final double aspectRatio;
  final Function(P2PStats)? onStatsUpdate;

  const VidstackWebView({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 9,
    this.onStatsUpdate,
  });

  @override
  State<VidstackWebView> createState() => _VidstackWebViewState();
}

class _VidstackWebViewState extends State<VidstackWebView>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final P2PStatsManager _statsManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statsManager = P2PStatsManager(onStatsUpdate: widget.onStatsUpdate);
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
          onMessageReceived: _statsManager.onPeerConnected)
      ..addJavaScriptChannel("onPeerClose",
          onMessageReceived: _statsManager.onPeerClose)
      ..addJavaScriptChannel("onChunkDownloaded",
          onMessageReceived: _statsManager.onChunkDownloaded)
      ..addJavaScriptChannel("onChunkUploaded",
          onMessageReceived: _statsManager.onChunkUploaded)
      ..loadFlutterAsset(widget.assetPath);

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

  void _updateP2PState(bool isP2PDisabled) {
    _controller.runJavaScript("window.updateP2PState($isP2PDisabled)");
  }

  void _destroyP2P() {
    _controller.runJavaScript("window.destroyP2P()");
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: WebViewWidget(controller: _controller),
    );
  }
}
