import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

double convertToMiB(double bytes) => bytes / 1024 / 1024;

class VidstackWebView extends StatefulWidget {
  final String assetPath;
  final double aspectRatio;
  final Function(double)? onChunkDownloadedByHttp;
  final Function(double)? onChunkDownloadedByP2P;
  final Function(double)? onChunkUploaded;
  final Function(String)? onPeerConnect;
  final Function(String)? onPeerClose;

  const VidstackWebView({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 9,
    this.onChunkDownloadedByHttp,
    this.onChunkDownloadedByP2P,
    this.onChunkUploaded,
    this.onPeerConnect,
    this.onPeerClose,
  });

  @override
  State<VidstackWebView> createState() => _VidstackWebViewState();
}

class _VidstackWebViewState extends State<VidstackWebView>
    with WidgetsBindingObserver {
  late final WebViewController _controller;

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

    void onPeerConnected(JavaScriptMessage msg) {
      final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
      final peerToAdd = msgData['peerId'] as String?;
      if (peerToAdd == null || peerToAdd.isEmpty) return;

      widget.onPeerConnect?.call(peerToAdd);
    }

    void onPeerClose(JavaScriptMessage msg) {
      final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
      final peerToRemove = msgData['peerId'] as String?;
      if (peerToRemove == null || peerToRemove.isEmpty) return;

      widget.onPeerClose?.call(peerToRemove);
    }

    void onChunkDownloaded(JavaScriptMessage msg) {
      final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
      final downloadedBytes = (msgData['downloadedBytes'] as num?)?.toDouble();
      final downloadSource = msgData['downloadSource'] as String?;
      if (downloadedBytes == null || downloadSource == null) return;

      final downloadedBytesInMiB = convertToMiB(downloadedBytes);

      if (downloadSource == 'http') {
        widget.onChunkDownloadedByHttp?.call(downloadedBytesInMiB);
      } else if (downloadSource == 'p2p') {
        widget.onChunkDownloadedByP2P?.call(downloadedBytesInMiB);
      }
    }

    void onChunkUploaded(JavaScriptMessage msg) {
      final msgData = jsonDecode(msg.message) as Map<String, dynamic>;
      final uploadedBytes = (msgData['uploadedBytes'] as num?)?.toDouble();
      if (uploadedBytes == null) return;

      widget.onChunkUploaded?.call(convertToMiB(uploadedBytes));
    }

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
          onMessageReceived: onPeerConnected)
      ..addJavaScriptChannel("onPeerClose", onMessageReceived: onPeerClose)
      ..addJavaScriptChannel("onChunkDownloaded",
          onMessageReceived: onChunkDownloaded)
      ..addJavaScriptChannel("onChunkUploaded",
          onMessageReceived: onChunkUploaded);

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.loadRequest(
        Uri.parse("http://192.168.1.111:3000/vidstack_player.html"));
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
