import 'package:circle/group_info_controller.dart';
import 'package:circle/qrcode/qrcode_page.dart';
import 'package:circle/screens/calendar_list_events.dart';
import 'package:circle/screens/chat_core/add_group_members.dart';
import 'package:circle/screens/chat_core/chat.dart';
import 'package:circle/screens/chat_core/view_nested_rooms.dart';
import 'package:circle/screens/posts/add_post_screen.dart';
import 'package:circle/screens/posts/news_feed_screen.dart';
import 'package:circle/screens/view_user_requests.dart';
import 'package:circle/utils/dynamiclink_helper.dart';
import 'package:circle/widgets/single_user_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../userinfo.dart';
import '../google_maps_screen.dart';
import '../main_circle_modified.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class GroupInfoScreen extends StatefulWidget {
  final types.Room groupRoom;

  const GroupInfoScreen({Key? key, required this.groupRoom}) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // bool loading = false;
  // bool updatingData = false;
  late String circleLink;
  final GroupInfoController groupInfoController = GroupInfoController();
  TextEditingController groupNameController = TextEditingController();
  TextEditingController groupDesController = TextEditingController();

  bool isManager = false;

  int reqCount = 0;

  @override
  initState() {
    groupNameController.text = widget.groupRoom.name!;
    groupDesController.text = widget.groupRoom.metadata!['description'] ?? "";

    List managers = (widget.groupRoom.metadata)?["managers"] ?? [];

    isManager = managers.contains(FirebaseAuth.instance.currentUser!.uid);

    Map metadata = widget.groupRoom.metadata ?? {};
    List req = metadata['userRequests'] ?? [];
    reqCount = req.length;

    super.initState();
  }

  uploadPhotoId() async {
    groupInfoController.pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (groupInfoController.pickedFile != null) {
      setState(() {});
    }

    print("upload photo id completed");
  }

  Future<String> uploadImageAndGetUrl() async {
    String downloadUrl = '';
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("file ${DateTime.now()}");
    UploadTask uploadTask =
        ref.putFile(File(groupInfoController.pickedFile!.path));
    await uploadTask.then((res) async {
      downloadUrl = await res.ref.getDownloadURL();
    });
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    bool tried = false;

    // print(widget.groupRoom.metadata);
    return FutureBuilder(
        future: _generateLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // print("into waiting");
            return Scaffold(
              appBar: AppBar(
                title: const Text("Circle Info"),
                centerTitle: true,
              ),
              body: const Center(
                child: Text("Generating group link .."),
              ),
            );
          }

          bool isChildCircle = (widget.groupRoom.metadata != null) && (widget.groupRoom.metadata!["isChildCircle"] ??  false);

          return Scaffold(
              appBar: AppBar(
                title: const Text("Circle Info"),
                centerTitle: true,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                        onTap: () {
                          Get.to(() => ChatPage(
                                room: widget.groupRoom,
                                groupChat: widget.groupRoom.type ==
                                    types.RoomType.group,
                              ));
                        },
                        child: const Icon(
                          Icons.message,
                          color: Colors.white,
                        )),
                  ),
                  10.horizontalSpace,
                  InkWell(
                      onTap: (){
                        Get.to(()=>AddPostScreen(groupRoom: widget.groupRoom,goToPostsPage: true,));
                      },
                      child: const Icon(Icons.add_box_sharp, color: Colors.green,)),
                  10.horizontalSpace
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView(
                  children: [
                    InkWell(
                      onTap: () async {
                        await uploadPhotoId();
                      },
                      child: SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: groupInfoController.pickedFile != null
                                  ? Image.file(
                                      File(
                                        groupInfoController.pickedFile!.path,
                                      ),
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover)
                                  : Image.network(widget.groupRoom.imageUrl!,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover),
                            ),
                            Positioned(
                                bottom: 5,
                                right: 20,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    padding: const EdgeInsets.all(5),
                                    child: const Icon(Icons.photo_camera)))
                          ],
                        ),
                      ),
                    ),

                    // ClipRRect(
                    //     borderRadius: BorderRadius.circular(50),
                    //     child: Image.network(
                    //       widget.groupRoom.imageUrl ??
                    //           "https://media.istockphoto.com/vectors/user-avatar-profile-icon-black-vector-illustration-vector-id1209654046?k=20&m=1209654046&s=612x612&w=0&h=Atw7VdjWG8KgyST8AXXJdmBkzn0lvgqyWod9vTb2XoE=",
                    //       width: 100,
                    //       height: 100,
                    //     )),
                    const SizedBox(
                      height: 10,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                              controller: groupNameController,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Circle name can't be empty";
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                label: Text(
                                  "Circle Name",
                                  style:
                                      TextStyle(fontWeight: FontWeight.normal),
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(),
                              ),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25)),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 70,
                            child: TextFormField(
                              // initialValue: "",
                              controller: groupDesController,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Circle name can't be empty";
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                  label: Text(
                                    "Circle Description",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal),
                                  ),
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(),
                                  hintText: "Enter Circle Description here"),
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal, fontSize: 20),
                              maxLines: null,
                              minLines: null,
                              readOnly: false,
                              expands: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),

                    if(!isChildCircle)
                      ElevatedButton(
                          onPressed: () {
                            Get.to(()=>NewsFeedScreen(groupRoom: widget.groupRoom,));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            fixedSize: Size.fromHeight(50.r)
                          ),
                          child: Row(

                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo),
                              SizedBox(width: 20.w,),
                              const Text("View Circle Posts"),
                            ],
                          )),
                    if(!isChildCircle)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Get.to(()=>QrCodeScreen(data: circleLink));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                fixedSize: Size.fromHeight(50.r)
                            ),
                            child: Row(

                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code),
                                SizedBox(width: 20.w,),
                                const Text("View QR Code"),
                              ],
                            )),
                      ),
                    5.verticalSpace,




                    true ? SizedBox() :

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(
                          height: 05,
                        ),

                        ElevatedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: circleLink));
                              Get.snackbar("Success", "Link Copied",
                                  backgroundColor: Colors.white);
                            },
                            child: const Text("Copy Invite Link")),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ((widget.groupRoom.metadata != null) &&
                                (widget.groupRoom.metadata!["isChildCircle"] ??
                                    false))
                            ? const SizedBox()
                            : Expanded(
                                child: ElevatedButton(
                                    onPressed: () {
                                      Get.off(AddMembersScreen(
                                          groupRoom: widget.groupRoom,
                                          invite: true));
                                    },
                                    child: Text((widget.groupRoom
                                                .metadata!["isChildCircle"] ??
                                            false)
                                        ? "Add Users"
                                        : "Invite Users")),
                              ),
                        SizedBox(
                          width: (widget.groupRoom.metadata != null) &&
                                  (widget.groupRoom
                                          .metadata!["isChildCircle"] ??
                                      false)
                              ? 0
                              : 20,
                          height: 0,
                        ),
                        ((widget.groupRoom.metadata != null) &&
                                (widget.groupRoom.metadata!["isChildCircle"] ??
                                    false))
                            ? const SizedBox()
                            : Expanded(
                                child: ElevatedButton(
                                    onPressed: () {
                                      Get.off(ViewNestedRoom(
                                          user: FirebaseAuth
                                              .instance.currentUser!,
                                          parentRoom: widget.groupRoom));
                                    },
                                    child: const Text("View Inner Circles")),
                              )
                      ],
                    ),



                    Row(
                      children: [
                    isManager
                    ?
                        Expanded(
                            child:  StreamBuilder(
                                    stream: FirebaseChatCore.instance
                                        .room(widget.groupRoom.id),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<types.Room>
                                            snapshot) {
                                      if (!(snapshot.connectionState ==
                                              ConnectionState.waiting ||
                                          (!(snapshot.hasData)))) {
                                        types.Room newRoom =
                                            snapshot.data!;
                                        Map metadata =
                                            newRoom.metadata ?? {};
                                        List req =
                                            metadata['userRequests'] ??
                                                [];
                                        reqCount = req.length;
                                      }

                                      return ElevatedButton(
                                          onPressed: () {
                                            Get.to(ViewUserRequestsPage(groupRoom: widget.groupRoom));
                                          },
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              const Text(
                                                  "Circle Requests"),
                                              reqCount != 0
                                                  ? Text(
                                                      "($reqCount)",
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .yellow,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold),
                                                    )
                                                  : SizedBox()
                                            ],
                                          ));
                                    })
                                ) : const SizedBox(),

                        ///commenting add user by uid code
                        // Expanded(
                        //   child: ElevatedButton(
                        //       onPressed: () async {
                        //         TextEditingController idController =
                        //             TextEditingController();
                        //         Map? userMap;
                        //         String? documentId;
                        //         tried = false;
                        //         await showDialog(
                        //             context: context,
                        //             builder: (_) => AlertDialog(
                        //                   title: Text('Enter User Id'),
                        //                   content: TextFormField(
                        //                     controller: idController,
                        //                     decoration: const InputDecoration(
                        //                       border: OutlineInputBorder(),
                        //                       focusedBorder:
                        //                           OutlineInputBorder(),
                        //                       enabledBorder:
                        //                           OutlineInputBorder(),
                        //                       isDense: true,
                        //                     ),
                        //                   ),
                        //                   actions: [
                        //                     ElevatedButton(
                        //                         onPressed: () {
                        //                           Navigator.pop(context);
                        //                         },
                        //                         child: Text("Cancel")),
                        //                     ElevatedButton(
                        //                         onPressed: () async {
                        //                           tried = true;
                        //                           QuerySnapshot<
                        //                                   Map<String, dynamic>>
                        //                               collection =
                        //                               await FirebaseFirestore
                        //                                   .instance
                        //                                   .collection("users")
                        //                                   .get();
                        //                           for (var document
                        //                               in collection.docs) {
                        //                             // QueryDocumentSnapshot<Map<String,dynamic>> doc = document;
                        //                             Map map = document.data();
                        //                             Map metadata =
                        //                                 map['metadata'];
                        //                             if (metadata['user_id'] ==
                        //                                 idController.text) {
                        //                               userMap = map;
                        //                               documentId = document.id;
                        //                               break;
                        //                             }
                        //                           }
                        //
                        //                           // DocumentSnapshot<Map>
                        //                           //     documentSnapshot =
                        //                           //     await FirebaseFirestore
                        //                           //         .instance
                        //                           //         .collection("users")
                        //                           //         .doc(
                        //                           //             idController.text)
                        //                           //         .get();
                        //                           // userMap =
                        //                           //     documentSnapshot.data();
                        //                           Navigator.pop(context);
                        //                         },
                        //                         child: Text("Confirm"))
                        //                   ],
                        //                 ));
                        //
                        //         if (userMap != null) {
                        //           await showDialog(
                        //               context: context,
                        //               builder: (_) => AlertDialog(
                        //                     title: const Text('User Found'),
                        //                     content: Container(
                        //                       margin: const EdgeInsets.only(
                        //                           right: 16),
                        //                       child: Column(
                        //                         mainAxisSize: MainAxisSize.min,
                        //                         children: [
                        //                           CircleAvatar(
                        //                             // backgroundColor: hasImage ? Colors.transparent : color,
                        //                             backgroundImage:
                        //                                 NetworkImage(userMap![
                        //                                     "imageUrl"]),
                        //                             radius: 40,
                        //                             child: null,
                        //                           ),
                        //                           const SizedBox(
                        //                             height: 15,
                        //                           ),
                        //                           Text(
                        //                               "${userMap!['firstName']} ${userMap!['lastName']}")
                        //                         ],
                        //                       ),
                        //                     ),
                        //                     actions: [
                        //                       ElevatedButton(
                        //                           onPressed: () {
                        //                             Navigator.pop(context);
                        //                           },
                        //                           child: Text("Cancel")),
                        //                       ElevatedButton(
                        //                           onPressed: () async {
                        //                             try {
                        //                               // await FirebaseFirestore.instance.collection("rooms")
                        //                               //     .doc(widget.groupRoom.id)
                        //                               //     .update({"users": userIds});
                        //                               await FirebaseFirestore
                        //                                   .instance
                        //                                   .collection("rooms")
                        //                                   .doc(widget
                        //                                       .groupRoom.id)
                        //                                   .update({
                        //                                 "userIds": FieldValue
                        //                                     .arrayUnion(
                        //                                         [documentId!])
                        //                               });
                        //                               Navigator.pop(context);
                        //                               Get.snackbar("Success",
                        //                                   "${userMap!['firstName']} is added to circle",
                        //                                   backgroundColor:
                        //                                       Colors.white);
                        //                             } catch (e) {
                        //                               Get.snackbar("error",
                        //                                   e.toString());
                        //                               print(e);
                        //                             }
                        //                           },
                        //                           child: Text("Add"))
                        //                     ],
                        //                   ));
                        //         } else if (tried) {
                        //           Get.snackbar("Sorry", "No user found",
                        //               backgroundColor: Colors.white);
                        //         }
                        //       },
                        //       child: const Text("Add User by uid")),
                        // ),

                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                            child: ElevatedButton(
                                onPressed: () {
                                  Get.to(CalendarListEventsScreen(
                                      circleId: widget.groupRoom.id));
                                },
                                child: Text("View Circle Events",textAlign: TextAlign.center,)))
                      ],
                    ),
                    10.verticalSpace,
                    MuteButton(groupRoom: widget.groupRoom),
                    const SizedBox(
                      height: 10,
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
                                      "Circle Id:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(child: Text(widget.groupRoom.name ?? "")),
                                    IconButton(
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(
                                              text: widget.groupRoom.name));
                                          Get.snackbar("Success",
                                              "Circle Id Copied to Clipboard",
                                              backgroundColor: Colors.white);
                                        },
                                        icon: const Icon(Icons.copy_outlined)),
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
                    const SizedBox(
                      height: 20,
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 8.0),
                    //   child: Row(
                    //     children: [
                    //       Text(
                    //         "${widget.groupRoom.users.length} Participants",
                    //         style: const TextStyle(
                    //             fontSize: 18, fontWeight: FontWeight.bold),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(
                    //   height: 10,
                    // ),

                    // Text(groupRoom.name!,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                    FutureBuilder(
                        future: allowedToSeeUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.data == false) {
                            return SizedBox();
                          }
                          return StreamBuilder(
                              stream: FirebaseChatCore.instance
                                  .room(widget.groupRoom.id),
                              builder: (context,
                                  AsyncSnapshot<types.Room> snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(
                                    height: 40,
                                    child:
                                        Center(child: Text("No Users to show")),
                                  );
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 40,
                                    child: Center(
                                        child: Text("Loading Users to show")),
                                  );
                                }

                                return Column(
                                  children: [
                                    ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            snapshot.data!.users.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12.0),
                                              child: Text(
                                                "${snapshot.data!.users.length} Participants",
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            );
                                          }

                                          types.User user =
                                              snapshot.data!.users[index - 1];

                                          List managers = (widget.groupRoom
                                                  .metadata)?["managers"] ??
                                              [];
                                          managers = managers
                                              .map((e) => e.toString())
                                              .toList();

                                          return SingleUserTile(
                                            user: user,
                                            groupRoom: widget.groupRoom,
                                            manager: managers.contains(user.id),
                                          );
                                        }),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Obx(() => ElevatedButton(
                                          onPressed: () {
                                            if (snapshot.hasData) {
                                              _onLocationPressed(
                                                  snapshot.data!.users);
                                            }
                                          },
                                          child: groupInfoController
                                                  .locationLoading.value
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Text(
                                                  "View Users Location"),
                                          style: ElevatedButton.styleFrom(
                                              fixedSize: const Size(210, 40),
                                              backgroundColor: Colors.pink),
                                        )),
                                  ],
                                );
                              });
                        }),
                  ],
                ),
              ),
              bottomNavigationBar: Obx(() => groupInfoController.loading.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 16),
                      child: ElevatedButton(
                        child: const Text("Save Info"),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // print("hello");
                            await _updateGroupData();
                            Get.offAll(
                              const MainCircle(),
                            );
                          }
                        },
                      ),
                    )));
        });
  }

  Future<bool> allowedToSeeUsers() async {
    if ((widget.groupRoom.metadata == null) ||
        (widget.groupRoom.metadata!["isChildCircle"] ?? false)) {
      return true;
    }

    List childCircles = widget.groupRoom.metadata?["childCircles"] ?? [];

    for (int i = 0; i < childCircles.length; i++) {
      types.Room room =
          await FirebaseChatCore.instance.room(childCircles[i]).first;
      List roomUsersIds = room.users.map((types.User user) => user.id).toList();

      if (roomUsersIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _generateLink() async {
    // if ((widget.groupRoom.metadata != null) &&
    //     (widget.groupRoom.metadata!['link'] != null)) {
    //   circleLink = widget.groupRoom.metadata!['link'];
    //   return;
    // }

    circleLink = await DynamicLinkHelper.createDynamicLink(widget.groupRoom.id);

    Map metadata = widget.groupRoom.metadata ?? {};
    metadata["link"] = circleLink;

    FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.groupRoom.id)
        .update({'metadata': metadata});
  }

  Future<void> _updateGroupData() async {
    // setState(() {
    //   loading = true;
    // });

    groupInfoController.loading.value = true;

    String? imageUrl = widget.groupRoom.imageUrl;

    if (groupInfoController.pickedFile != null) {
      imageUrl = await uploadImageAndGetUrl();
    }

    Map metadata = widget.groupRoom.metadata ?? {};
    metadata['description'] = groupDesController.text;

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.groupRoom.id)
        .update({
      "name": groupNameController.text,
      'metadata': metadata,
      'imageUrl': imageUrl
    });

    groupInfoController.loading.value = false;
  }

  Future<void> _onLocationPressed(List<types.User> users) async {
    List<types.User> updatedUsers = List.castFrom(users);
    groupInfoController.locationLoading.value = true;

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      Get.snackbar("Request Failed", "Enable service Location");
      groupInfoController.locationLoading.value = false;

      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        Get.snackbar("Request Failed", "Location permission denied",
            backgroundColor: Colors.white);
        groupInfoController.locationLoading.value = false;

        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      Get.snackbar("Request Failed",
          "Location permissions are permanently denied, we cannot request permissions. Enable from app settings",
          backgroundColor: Colors.white);

      groupInfoController.locationLoading.value = false;

      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    await CurrentUserInfo.getCurrentUserMapFresh();
    updatedUsers.removeWhere(
        (element) => element.id == FirebaseAuth.instance.currentUser!.uid);
    groupInfoController.locationLoading.value = false;
    Get.to(() => GoogleMapScreen(
          myCurrentPosition: position,
          users: users,
        ));
  }
}

class MuteButton extends StatefulWidget {
  final types.Room groupRoom;

  const MuteButton({Key? key, required this.groupRoom}) : super(key: key);

  @override
  State<MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<MuteButton> {
  bool muted = false;
  List mutedIds = [];
  Map metadata = {};
  bool loading = false;

  @override
  void initState() {
    metadata = widget.groupRoom.metadata ?? {};
    mutedIds = metadata['mutedBy'] ?? [];
    for (var element in mutedIds) {
      element = element.toString();
    }

    ///If already muted
    if (mutedIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
      muted = true;
    }

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : ElevatedButton(
            onPressed: () async {
              setState(() {
                loading = true;
              });

              if (muted) {
                mutedIds.removeWhere((element) =>
                    element == FirebaseAuth.instance.currentUser!.uid);
                muted = false;
              } else {
                mutedIds.add(FirebaseAuth.instance.currentUser!.uid);
                muted = true;
              }

              metadata['mutedBy'] = mutedIds;
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.groupRoom.id)
                  .update({'metadata': metadata});
              setState(() {
                loading = false;
              });

              if (muted) {
                Get.snackbar("Success", "Circle Muted",
                    backgroundColor: Colors.white);
              } else {
                Get.snackbar("Success", "Circle Unmuted",
                    backgroundColor: Colors.white);
              }
            },
            child: Text(muted ? "Unmute" : "Mute"),
            style: ElevatedButton.styleFrom(
              primary: !muted ? Colors.red : Colors.green,
            ),
          );
  }
}
