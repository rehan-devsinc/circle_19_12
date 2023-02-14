import 'package:circle/qrcode/invite_link_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({Key? key,required this.data}) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan QR Code"),
      ),
      body: SizedBox(
        width: Get.width,
        child: Column(
          children: [
            // 20.verticalSpace,
            // Text("Scan QR Code", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15.sp, color: Colors.deepPurple),),
            20.verticalSpace,
            QrImage(
              data: data,
              version: QrVersions.auto,
            ),
            20.verticalSpace,
            Text("Or",style: TextStyle(fontSize: 16.sp),),
            20.verticalSpace,
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                  onPressed: () {
                    Get.to(()=>InviteLinkScreen(circleLink: data));
                    },
                  child: const Text("View Invite Link"),
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(Get.width, 45.h)
                ),
              ),
            ),
            30.verticalSpace,

          ],
        ),
      ),
    );
  }
}
