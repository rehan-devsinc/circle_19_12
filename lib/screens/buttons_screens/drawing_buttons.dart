import 'package:circle/screens/drawing/new_drawing_screen.dart';
import 'package:circle/screens/drawing/view_drawings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import '../chat_core/users.dart';
import '../profile_screen.dart';


class DrawingButtonsScreen extends StatelessWidget {
  const DrawingButtonsScreen({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {

    final double height = 40.h;
    final Size fixedSize = Size(200.w, 80.h);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Drawing"),
      ),
      body:   Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(),
          ElevatedButton(

            ///VIEW CIRCLE INVITES REPLACEMENT
              style: ElevatedButton.styleFrom(
                  fixedSize:fixedSize,
                backgroundColor: Colors.green
              ),
              onPressed: () {
                Get.to(()=>const NewDrawingScreen());
              },

            ///VIEW CIRCLE INVITES REPLACEMENT
              child: const Text("Create New Drawing",textAlign: TextAlign.center)),
          SizedBox(height: height,),


          ElevatedButton(

            ///VIEW CIRCLE INVITES REPLACEMENT
              style: ElevatedButton.styleFrom(
                  fixedSize: fixedSize
              ),
              onPressed: () {
                Get.to(()=>MyDrawingsList());
              },

            ///VIEW CIRCLE INVITES REPLACEMENT
              child: const Text("View My Drawings",textAlign: TextAlign.center)),





        ],
      ),
    );
  }
}
