import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HolderRuntimeView extends StatelessWidget {
  const HolderRuntimeView({required this.controller, super.key});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: IgnorePointer(child: WebViewWidget(controller: controller)),
    );
  }
}
