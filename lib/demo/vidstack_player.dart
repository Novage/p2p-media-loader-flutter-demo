import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class VidstackPlayer extends StatefulWidget {
  const VidstackPlayer({super.key});

  @override
  State<VidstackPlayer> createState() => _VidstackPlayerState();
}

class _VidstackPlayerState extends State<VidstackPlayer> {
  late final WebViewController controller;
  final double aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
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
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    var platform = controller.platform;

    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadFlutterAsset('assets/vidstack_player.html');
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
              child: WebViewWidget(
                controller: controller,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle button press
              },
              child: const Text('Click Me'),
            ),
          ],
        ),
      ),
    );
  }
}
