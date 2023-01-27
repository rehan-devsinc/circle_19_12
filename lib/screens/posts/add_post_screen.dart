import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:circle/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddPostScreen extends StatefulWidget {
   const AddPostScreen({Key? key, required this.groupRoom}) : super(key: key);

   final types.Room groupRoom;

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final List<XFile> pickedFiles = [];
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
    super.initState();
  }

  String? loadingText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Create Post"),
        actions:  [

          if(loadingText==null)
          Padding(
            padding:  EdgeInsets.symmetric(vertical: 7.h,horizontal: 10.w),
            child: ElevatedButton(
                onPressed: () async{
                  await uploadPost();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                ),
                child: const Text("Post")),
          )
        ],
      ),
      body: loadingText != null ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            10.verticalSpace,
            Text(loadingText!),

          ],
        ),
      ) : Padding(
        padding:  EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          children: [
            SizedBox(
              height: 0.2.sh,
              child: TextFormField(
                controller: textEditingController,
                maxLines: 5,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 25.sp),
                cursorHeight: 30.h,
                decoration:  InputDecoration(
                  // fillColor: Colors.grey.withOpacity(0.4),
                  // filled: true,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  hintText: "Write something in ${widget.groupRoom.name} feed.",
                  hintStyle: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: pickedFiles.length,
                    itemBuilder: (context,index){
                      return _buildPickedPicture(pickedFiles[index]);
                    }),

            )

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          pickPhoto();
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> uploadPost()async{


    String uid = const Uuid().v4();
    List<String> images = [];

    loadingText = 'uploading images';
    setState(() {});


    ///add to images
    for (var element in pickedFiles)  {
      images.add(await uploadImageAndGetUrl(element));
    }

    PostModel post = PostModel(id: uid, circleId: widget.groupRoom.id, createdAt: DateTime.now(), authorId: FirebaseAuth.instance.currentUser!.uid, likedBy: [], picturesList: images, videosList: [],text: textEditingController.text);

    loadingText = 'uploading post';
    setState(() {});

    await FirebaseFirestore.instance.collection("posts").doc(uid).set(post.toJson());

    loadingText = null;
    Get.back();

  }

  Future<String> uploadImageAndGetUrl(XFile pickedFile) async {
    String downloadUrl = '';
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("file ${DateTime.now()}");
    UploadTask uploadTask = ref.putFile(File(pickedFile.path));
    await uploadTask.then((res) async{
      downloadUrl = await res.ref.getDownloadURL();
    });
    return downloadUrl;
  }


  Widget _buildPickedPicture(XFile xFile){
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 10.h),
      child: Container(
        color: Colors.pink,
          child: Stack(
            children: [
              Image.file(
                File(xFile.path),
                height: 200.h,
                width: 1.sw,
                fit: BoxFit.cover,
              ),

              Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: InkWell(
                      onTap: (){
                        pickedFiles.removeWhere((element) => element.path==xFile.path);
                        setState(() {});
                      },
                      child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white
                          ),
                          padding: EdgeInsets.all(5.r),
                          child: const Icon(Icons.delete_forever,color: Colors.red,))))
            ],
          ),

      ),
    );
  }

   void pickPhoto() async {
    pickedFiles.addAll(
        await ImagePicker().pickMultiImage(imageQuality: 10,)
            ?? []);
    setState(() {

    });
   }


}
