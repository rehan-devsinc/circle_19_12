import 'dart:io';
import 'package:circle/controllers/tags_matching_controller.dart';
import 'package:circle/phone_login/collect_user_info.dart';
import 'package:circle/profileController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_core/rooms.dart';
import 'chat_core/users.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  ProfileController profileController = ProfileController();

  TextEditingController hobbyController = TextEditingController();
  TextEditingController musicController = TextEditingController();
  TextEditingController bookController = TextEditingController();
  TextEditingController bandController = TextEditingController();

  TagsController tagsController = TagsController();

  Map metadata = {};
  List<String> myTags = [];

  @override
  Widget build(BuildContext context) {
    print(Get.width);
    double paddingRes30 = Get.width * 0.070093;

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.data == null ||
              snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: SizedBox(
                height: Get.height,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          Map<String, dynamic> userMap = snapshot.data!.data()!;

          metadata = userMap['metadata'] ?? {};

          hobbyController.text = metadata['fvrtHobby'] ?? "";
          musicController.text = metadata['fvrtMusic'] ?? "";
          bandController.text = metadata['fvrtBand'] ?? "";
          bookController.text = metadata['fvrtBook'] ?? "";
          // passwordController.text = userMap['firstName'];
          // emailController.text = FirebaseAuth.instance.currentUser!.email;

          print(userMap);
          if (userMap['metadata'] == null) {
            Get.offAll(CollectUserInfo(
                phoneNo: FirebaseAuth.instance.currentUser!.phoneNumber!));
            return SizedBox();
          }

           myTags = ((metadata['tags'] ?? []) as List)
              .map((e) => e.toString())
              .toList();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile Settings'),
              actions: [
                Obx(() => profileController.loading.value
                    ? const SizedBox(
                        height: 40,
                        child: CircularProgressIndicator(),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 7.h, horizontal: 10.w),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink),
                            onPressed: () async {
                              profileController.saveInfo(
                                  hobby: hobbyController.text,
                                  music: musicController.text,
                                  imageUrl: userMap['imageUrl'],
                                  book: bookController.text,
                                  band: bandController.text,
                                  metadata: metadata);
                            },
                            child: const Text('Save')),
                      ))
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingRes30),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      UserPhotoWidget(
                        imageUrl: userMap['imageUrl'],
                        profileController: profileController,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                              child: const Text("My Friends",
                                  textAlign: TextAlign.center),
                              onPressed: () {
                                Get.to(const UsersPage(
                                  onlyUsers: true,
                                  friendsOnly: true,
                                ));
                              }),
                          ElevatedButton(
                              child: const Text("My Circles",
                                  textAlign: TextAlign.center),
                              onPressed: () {
                                Get.to(const RoomsPage(goToInfoPage: true,hideLogout: true, appBarTitle: "Circles",));
                              }),

                        ],
                      ),



                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "User Id:",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                          child: Text(
                                        metadata['user_id'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      )),
                                      IconButton(
                                          onPressed: () async {
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: metadata['user_id']));
                                            Get.snackbar("Success",
                                                "User Id Copied to Clipboard",
                                                backgroundColor: Colors.white);
                                          },
                                          icon:
                                              const Icon(Icons.copy_outlined)),
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: paddingRes30, vertical: 8),
                        child: _buildCustomTextField("Favourite Hobby",
                            readOnly: false,
                            textEditingController: hobbyController),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: paddingRes30, vertical: 8),
                        child: _buildCustomTextField("Favourite Music",
                            readOnly: false,
                            textEditingController: musicController),
                      ),
                      // ///TODO REPLACE EMAIL
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: paddingRes30, vertical: 8),
                        child: _buildCustomTextField("Favourite Band",
                            readOnly: false,
                            textEditingController: bandController),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: paddingRes30, vertical: 8),
                        child: _buildCustomTextField("Favourite Book",
                            readOnly: false,
                            textEditingController: bookController),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildTagsPortion(myTags,context),
                      40.verticalSpace,
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                    await insertTag(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                    ],
                  ),
                ),
                5.verticalSpace,
                Text(
                  "Add Tag",
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                )
              ],
            ),
          );
        });
  }

  Widget _buildCustomTextField(String hintText,
      {bool readOnly = false,
      required TextEditingController textEditingController}) {
    return TextFormField(
      controller: textEditingController,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: hintText,
        hintStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)
            // borderSide: const BorderSide(color: darkMain, ),
            // borderRadius: BorderRadius.circular(30),
            ),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)
                // borderSide: const BorderSide(color: darkMain, ),
                // borderRadius: BorderRadius.circular(30),
                ),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)
                // borderSide: const BorderSide(color: darkMain, ),
                // borderRadius: BorderRadius.circular(30),
                ),
        disabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)
                // borderSide: const BorderSide(color: darkMain, ),
                // borderRadius: BorderRadius.circular(30),
                ),

        // isDense: true,
        filled: true,
        contentPadding: const EdgeInsets.only(top: 5, left: 25),
        fillColor: Colors.white,
      ),
      style: const TextStyle(
        color: Colors.black,
      ),
      cursorColor: Colors.black,
    );
  }

  Widget _buildTagsPortion(List<String> myTags, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
             Text(
              "Your Favourite Tags: ",
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18.sp),
            ),
            30.horizontalSpace,
            if (myTags.isEmpty)
              const Text("EMPTY",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic)),
          ],
        ),
        10.verticalSpace,
        Padding(
          padding:  EdgeInsets.only(left: 0.w,right: 40.w),
          child: Text("We will connect you with relevant circles based on your favourite tags.", style: TextStyle(color: Colors.grey[700]),),
        ),
        5.verticalSpace,
        if (myTags.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 50.w, top: 10.h),
            child: SizedBox(
              width: Get.width,
              child: Wrap(
                alignment: WrapAlignment.start,
                // runAlignment: WrapAlignment.start,
                // crossAxisAlignment: WrapCrossAlignment.start,
                runSpacing: 10.h,
                spacing: 12.w,
                children: [
                  for (var i in myTags) _buildSingleTag(i,context),
                ],
              ),
            ),
          ),
        20.verticalSpace,

      ],
    );
  }

  Widget _buildSingleTag(String tag, BuildContext context,
      {bool deleteIcon = true,void Function()? onTap}) {
    return InkWell(
      onTap: deleteIcon ?  (){
        deleteTag(context, tag);
      } : onTap,
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.normal),
            ),
            if(deleteIcon)
              ...[ 5.horizontalSpace,
                Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16.r,
                )]
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.pink, borderRadius: BorderRadius.circular(15.r)),
      ),
    );
  }


  Future insertTag(BuildContext context) async {
    TextEditingController nameController = TextEditingController();

    bool tagsInitiated = false;

    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Enter Tag Name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  FutureBuilder(
                    future: getSuggestedTags(),
                    builder: (context,AsyncSnapshot<List<String>> snapshot) {
                      return _buildSuggestedTags(snapshot.data ?? [], context,nameController);
                    }
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")),

                // 5.horizontalSpace,

                ElevatedButton(
                  onPressed: () async {
                    List<String> tagsList = ((metadata['tags'] ?? []) as List)
                        .map((e) => e.toString())
                        .toList();

                    if (nameController.text.trim().isEmpty) {
                      Get.snackbar("Error", "Tag cant be empty",
                          backgroundColor: Colors.white);
                      return;
                    } else if (tagsList
                        .contains(nameController.text.toLowerCase())) {
                      Get.snackbar("Error", "Tag already exists",
                          backgroundColor: Colors.white
                      );
                      return;
                    }

                    try {
                      tagsList.add(nameController.text);

                      metadata['tags'] = tagsList;

                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({'metadata': metadata});

                      if(!tagsInitiated){
                        tagsInitiated = true;
                        tagsController.initiateMatching(delay: const Duration(seconds: 5));
                      }

                    } catch (e) {
                      print(e);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add",
                    // style: TextStyle(color: Colors.green),
                  ),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                )
              ],
            ));
  }

  Future deleteTag(BuildContext context, String tag) async {

    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title:  Text("Delete '$tag'"),
          content: const Text("Are you sure you want to delete this tag?"),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel")),

            // 5.horizontalSpace,

            ElevatedButton(
              onPressed: () async {
                List<String> tagsList = ((metadata['tags'] ?? []) as List)
                    .map((e) => e.toString())
                    .toList();

                try {
                  tagsList.removeWhere((element) => element==(tag));

                  metadata['tags'] = tagsList;

                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({'metadata': metadata});
                } catch (e) {
                  print(e);
                }

                Navigator.pop(context);
              },
              child: const Text(
                "Confirm",
                // style: TextStyle(color: Colors.green),
              ),
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.red),
            )
          ],
        ));
  }


  Widget _buildSuggestedTags(List<String> suggestedTags, BuildContext context,TextEditingController textEditingController,
      ) {

    return Column(
      children: [
        8.verticalSpace,
        Row(
          children: [
            const Text(
              "Suggested Tags: ",
              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.pink),
            ),
            10.horizontalSpace,
            if (suggestedTags.isEmpty)
              const Text("NONE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontStyle: FontStyle.normal)),
          ],
        ),
        if (suggestedTags.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: SizedBox(
              width: Get.width,
              child: Wrap(
                alignment: WrapAlignment.start,
                // runAlignment: WrapAlignment.start,
                // crossAxisAlignment: WrapCrossAlignment.start,
                runSpacing: 10.h,
                spacing: 12.w,
                children: [
                  for (var i in suggestedTags) _buildSingleTag(i,context,deleteIcon: false,
                      onTap: (){
                    textEditingController.text = i;
                      }

                  ),
                ],
              ),
            ),
          )
      ],
    );
  }

  Future<List<String>> getSuggestedTags() async{

    List<String> allTags = [];

   QuerySnapshot<Map<String,dynamic>> querySnapshot = await FirebaseFirestore.instance.collection("users").get();
   for (var element in querySnapshot.docs) {
     if((element.data())['metadata'] == null || ((element.data())['metadata'])['tags']==null){
       continue;
     }

     List<String> userTags = (((element.data())['metadata'])['tags'] as List).map((e) => e.toString()).toList();
     allTags.addAll(userTags);
   }

   allTags.removeWhere((element) => myTags.contains(element.toString()));

   return allTags.toSet().toList();

  }
}

class UserPhotoWidget extends StatefulWidget {
  const UserPhotoWidget(
      {Key? key, required this.imageUrl, required this.profileController})
      : super(key: key);

  final String imageUrl;
  final ProfileController profileController;

  @override
  State<UserPhotoWidget> createState() => _UserPhotoWidgetState();
}

class _UserPhotoWidgetState extends State<UserPhotoWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await uploadPhotoId();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: widget.profileController.pickedFile != null
                ? Image.file(
                    File(
                      widget.profileController.pickedFile!.path,
                    ),
                    height: 150.h,
                    width: 150.h,
                    fit: BoxFit.cover)
                : Image.network(widget.imageUrl,
                    height: 150.h, width: 150.h, fit: BoxFit.cover),
          ),
          Positioned(
              bottom: 0,
              right: 10,
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.photo_camera)))
        ],
      ),
    );
  }

  uploadPhotoId() async {
    widget.profileController.pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 10);
    if (widget.profileController.pickedFile != null) {
      setState(() {});
    }
  }
}
