import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class InviteLinkScreen extends StatelessWidget {
  const InviteLinkScreen({Key? key, required this.circleLink}) : super(key: key);

  final String circleLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Circle Invite Link"),
      ),
      body: Column(
        children: [
          30.verticalSpace,
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5)),
            child: Row(
              children: [
                Expanded(child: Text(circleLink)),
                // InkWell(
                //   onTap: () {
                //     Clipboard.setData(
                //         ClipboardData(text: widget.groupRoom.id));
                //     Get.snackbar("Success", "Text Copied");
                //   },
                //   child: const Icon(Icons.copy),
                // ),
              ],
            ),
          ),
          20.verticalSpace,

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    fixedSize: Size(Get.width, 45.h)
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: circleLink));
                  Get.snackbar("Success", "Link Copied",
                      backgroundColor: Colors.white);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy),
                    10.horizontalSpace,
                    const Text("Copy Invite Link"),
                  ],
                )),
          ),

        ],
      ),

    );
  }
}
