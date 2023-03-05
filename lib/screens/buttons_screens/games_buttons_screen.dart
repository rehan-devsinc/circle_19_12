import 'package:circle/screens/webview/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class GamesButtonsScreen extends StatelessWidget {
  const GamesButtonsScreen({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final Size fixedSize = Size(200.w, 80.h);
    final double height = 40;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Games"),

      ),
      body:   Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(),
          ElevatedButton(

              style: ElevatedButton.styleFrom(
                  fixedSize: fixedSize,
                backgroundColor: Colors.green
              ),
              onPressed: () {
                Get.to(const GameWebViewScreen(url: "https://gameforge.com/en-US/littlegames/fidget-spinner-extreme/"));
              },

              child: const Text("Fidget Spinner Extreme",textAlign: TextAlign.center)),
          SizedBox(height: height,),


          ElevatedButton(

              style: ElevatedButton.styleFrom(
                  fixedSize: fixedSize,
                  backgroundColor: Colors.orangeAccent

              ),
              onPressed: () {
                Get.to(const GameWebViewScreen(url: "https://gameforge.com/en-US/littlegames/hand-spinner-simulator/"));
              },

              child: const Text("Hand Spinner Simulator",textAlign: TextAlign.center)),
          SizedBox(height: height,),

          ElevatedButton(

            ///VIEW CIRCLE INVITES REPLACEMENT
              style: ElevatedButton.styleFrom(
                  fixedSize: fixedSize,
                  backgroundColor: Colors.purple
              ),
              onPressed: () {
                Get.to(const GameWebViewScreen(url: "https://gameforge.com/en-US/littlegames/fidget-games/"));
              },
              child: const Text("Browse All Fidget Games",textAlign: TextAlign.center))

        ],
      ),
    );
  }
}
