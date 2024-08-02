import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  late InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _destroyP2P();
    _controller?.dispose();
    super.dispose();
  }

  void _initializeWebViewController(InAppWebViewController controller) {
    _controller = controller;

    _controller?.addJavaScriptHandler(
        handlerName: 'onPeerConnect',
        callback: (args) {
          final peerToAdd = args[0].peerId as String?;
          if (peerToAdd == null || peerToAdd.isEmpty) return;
          widget.onPeerConnect?.call(peerToAdd);
        });

    _controller?.addJavaScriptHandler(
        handlerName: 'onPeerClose',
        callback: (args) {
          final peerToRemove = args[0].peerId as String?;
          if (peerToRemove == null || peerToRemove.isEmpty) return;
          widget.onPeerClose?.call(peerToRemove);
        });

    _controller?.addJavaScriptHandler(
        handlerName: 'onChunkDownloaded',
        callback: (args) {
          final downloadedBytes = (args[0] as num?)?.toDouble();
          final downloadSource = args[1] as String?;
          if (downloadedBytes == null || downloadSource == null) return;

          final downloadedBytesInMiB = convertToMiB(downloadedBytes);

          if (downloadSource == 'http') {
            widget.onChunkDownloadedByHttp?.call(downloadedBytesInMiB);
          } else if (downloadSource == 'p2p') {
            widget.onChunkDownloadedByP2P?.call(downloadedBytesInMiB);
          }
        });

    _controller?.addJavaScriptHandler(
        handlerName: 'onChunkUploaded',
        callback: (args) {
          final uploadedBytes = (args[0] as num?)?.toDouble();
          if (uploadedBytes == null) return;

          widget.onChunkUploaded?.call(convertToMiB(uploadedBytes));
        });

    _controller?.loadFile(assetFilePath: widget.assetPath);
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
    _controller?.evaluateJavascript(
        source: "window.updateP2PState($isP2PDisabled)");
  }

  void _destroyP2P() {
    _controller?.evaluateJavascript(source: "window.destroyP2P()");
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
          ),
          onWebViewCreated: _initializeWebViewController,
        ));
  }
}
