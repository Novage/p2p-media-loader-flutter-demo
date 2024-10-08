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

class _VidstackWebViewState extends State<VidstackWebView> {
  void _initializeWebViewController(InAppWebViewController controller) {
    _applyJavaScriptHandlers(controller);
    controller.loadFile(assetFilePath: widget.assetPath);
  }

  void _applyJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
        handlerName: 'onPeerConnect', callback: _handlePeerConnect);
    controller.addJavaScriptHandler(
        handlerName: 'onPeerClose', callback: _handlePeerClose);
    controller.addJavaScriptHandler(
        handlerName: 'onChunkDownloaded', callback: _handleChunkDownloaded);
    controller.addJavaScriptHandler(
        handlerName: 'onChunkUploaded', callback: _handleChunkUploaded);
  }

  void _handlePeerConnect(List<dynamic> args) {
    if (args.isEmpty) return;
    final peerId = (args[0] as Map<String, dynamic>)['peerId'] as String?;
    if (peerId == null || peerId.isEmpty) return;

    widget.onPeerConnect?.call(peerId);
  }

  void _handlePeerClose(List<dynamic> args) {
    if (args.isEmpty) return;
    final peerId = (args[0] as Map<String, dynamic>)['peerId'] as String?;
    if (peerId == null || peerId.isEmpty) return;

    widget.onPeerClose?.call(peerId);
  }

  void _handleChunkDownloaded(List<dynamic> args) {
    final downloadedBytes = (args[0] as num?)?.toDouble();
    final downloadSource = args[1] as String?;

    if (downloadedBytes != null && downloadSource != null) {
      final downloadedBytesInMiB = convertToMiB(downloadedBytes);
      if (downloadSource == 'http') {
        widget.onChunkDownloadedByHttp?.call(downloadedBytesInMiB);
      } else if (downloadSource == 'p2p') {
        widget.onChunkDownloadedByP2P?.call(downloadedBytesInMiB);
      }
    }
  }

  void _handleChunkUploaded(List<dynamic> args) {
    final uploadedBytes = (args[0] as num?)?.toDouble();
    if (uploadedBytes == null) return;
    widget.onChunkUploaded?.call(convertToMiB(uploadedBytes));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true,
            allowUniversalAccessFromFileURLs: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: _initializeWebViewController,
        ));
  }
}
