import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GameWebViewScreen extends StatefulWidget {
  const GameWebViewScreen({Key? key, required this.url}) : super(key: key);
  final String url;

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {

  late WebViewController controller;

  bool loading = true;

  @override
  void initState() {

    initiateController();

    // TODO: implement initState
    super.initState();
  }

  Future initiateController() async{

    print("heello");
    String js =
        "document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=1024px, initial-scale=' + (document.documentElement.clientWidth / 1024));";

    controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("dummy", onMessageReceived: (JavaScriptMessage msg){
        print("js channel message: $msg");
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            Get.snackbar("Error ${error.errorCode}",error.description);
            Get.back();
          },
          // onNavigationRequest: (NavigationRequest request) {
          //   if (request.url.startsWith('https://www.youtube.com/')) {
          //     return NavigationDecision.prevent;
          //   }
          //   return NavigationDecision.navigate;
          // },
        ),
      );

    await controller.runJavaScript(js);
    await controller.loadRequest(Uri.parse(widget.url));
    loading = false;
    setState(() {

    });

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Color(0xFF091d59),
        elevation: 0,
        toolbarHeight: kToolbarHeight-20,
      ),
      body: loading? const Center(child: CircularProgressIndicator()) : WebViewWidget(controller: controller,),
    );
  }
}
