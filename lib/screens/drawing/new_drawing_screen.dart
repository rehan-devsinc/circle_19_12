import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class NewDrawingScreen extends StatefulWidget {
  const NewDrawingScreen({Key? key}) : super(key: key);

  @override
  State<NewDrawingScreen> createState() => _NewDrawingScreenState();
}

class _NewDrawingScreenState extends State<NewDrawingScreen> {
  final DrawingController _drawingController = DrawingController();

  String? loadingText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Drawing"),
        actions:  [

          if(loadingText==null)
            Padding(
              padding:  EdgeInsets.symmetric(vertical: 7.h,horizontal: 10.w),
              child: ElevatedButton(
                  onPressed: () async{
                    await _saveAndUploadImg();

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Save")),
            )
        ],
      ),
      body: loadingText!=null ?  Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            10.verticalSpace,
            Text(loadingText!),

          ],
        ),
      ) : DrawingBoard(
        controller: _drawingController,
        background: Container(
            height: Get.height,
            width: double.infinity,
            color: Colors.white
        ),
        showDefaultActions: true, /// 开启默认操作选项
        showDefaultTools: true,   /// 开启默认工具栏
      ),
      backgroundColor: loadingText==null ? Colors.white70 : null,
    );
  }

  Future<void> _saveAndUploadImg() async {

    if(_drawingController.currentIndex==0){
      Get.snackbar("Request Failed", "Please draw something and then proceed to save the drawing",backgroundColor: Colors.white);
      return;
    }

    try {

      setState(() {
        loadingText = "Saving Drawing";
      });

      Uint8List uInt8list = (await _drawingController.getImageData())!.buffer
          .asUint8List();

      final tempDir = await getTemporaryDirectory();
      File file = await File('${tempDir.path}/image.png').create();
      file.writeAsBytesSync(uInt8list);

      setState(() {
        loadingText = "Uploading Drawing";
      });

      String url = await uploadImageAndGetUrl(file);
      await _uploadUrl(url);

      Get.back();

      Get.snackbar("Success","Drawing Saved",backgroundColor: Colors.white);
    }
    catch(e){
      setState(() {
        loadingText = null;
      });
      print("custom error: ${e.toString()}");
      Get.snackbar("Request Failed",e.toString());

    }

    loadingText=null;
  }

  Future<void> _uploadUrl(String url)async{
    DocumentSnapshot<Map<String,dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    Map<String,dynamic> userMap = documentSnapshot.data()!;
    Map<String,dynamic> metadata = userMap['metadata'] ?? {};
    List drawingUrls = metadata['drawingUrls'] ?? [];

    drawingUrls.add(url);
    metadata['drawingUrls'] = drawingUrls;

    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'metadata' : metadata
    });
  }

  Future<String> uploadImageAndGetUrl(File pickedFile) async {
    String downloadUrl = '';
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("file ${DateTime.now()}");
    UploadTask uploadTask = ref.putFile(File(pickedFile.path));
    await uploadTask.then((res) async{
      downloadUrl = await res.ref.getDownloadURL();
    });
    return downloadUrl;
  }


}
