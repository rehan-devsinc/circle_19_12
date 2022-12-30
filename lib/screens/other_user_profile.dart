import 'package:circle/screens/google_maps_screen.dart';
import 'package:circle/utils/profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../userinfo.dart';
import 'chat_core/chat.dart';

class OtherUserProfileScreen extends StatefulWidget {
  const OtherUserProfileScreen({Key? key, required this.otherUser})
      : super(key: key);

  final types.User otherUser;

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  bool chatLoading = false;
  bool addFriendLoading = false;
  bool locationLoading = false;
  bool isFriend = false;

  TextEditingController hobbyController = TextEditingController();
  TextEditingController musicController = TextEditingController();
  TextEditingController bookController = TextEditingController();
  TextEditingController bandController = TextEditingController();

  @override
  initState() {
    isFriend = ProfileRepo.isFriend(widget.otherUser);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(Get.width);
    double paddingRes30 = Get.width * 0.070093;
    Map metadata = widget.otherUser.metadata!;

    hobbyController.text = metadata['fvrtHobby'] ?? "";
    musicController.text = metadata['fvrtMusic'] ?? "";
    bandController.text = metadata['fvrtBand'] ?? "";
    bookController.text = metadata['fvrtBook'] ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(widget.otherUser.imageUrl!,
                  height: 200, width: 200, fit: BoxFit.cover),
            ),
            SizedBox(
              height: Get.height * 0.0777 * 0.5,
            ),
            Text(
              (widget.otherUser.firstName ?? "") +
                  ((widget.otherUser.lastName ?? "")),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _handlePressed(context);
                  },
                  child: chatLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Chat"),
                  style: ElevatedButton.styleFrom(fixedSize: Size(100, 40)),
                ),
                // SizedBox(width: 20,),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      addFriendLoading = true;
                    });

                    ///adding
                    if (!isFriend) {
                      isFriend = await ProfileRepo.addFriend(widget.otherUser);
                    }

                    ///removing
                    else {
                      isFriend =
                          !(await ProfileRepo.removeFriend(widget.otherUser));
                    }

                    setState(() {
                      addFriendLoading = false;
                    });
                  },
                  child: addFriendLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(!(isFriend) ? "Add Friend" : "Unfriend"),
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(100, 40),
                      backgroundColor: !(isFriend) ? Colors.green : Colors.red),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed: () async {
              Map metadata =   widget.otherUser.metadata ?? {};
              if(metadata['locationSharing'] ?? false){
                _onLocationPressed();
              }
              else{
                Get.snackbar("Request Denies", "User has disabled his location sharing");
              }


              },
              child: locationLoading
                  ? const CircularProgressIndicator(
                color: Colors.white,

              )
                  : const Text( "View Location" ),
              style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 40),
                  backgroundColor:  Colors.pink),
            ),
            const SizedBox(height: 20,),


            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
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
                                      ClipboardData(text: metadata['user_id']));
                                  Get.snackbar(
                                      "Success", "User Id Copied to Clipboard",
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
              height: 30,
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: paddingRes30, vertical: 8),
              child: _buildCustomTextField(
                "Favourite Hobby",
                hobbyController,
                readOnly: true,
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: paddingRes30, vertical: 8),
              child: _buildCustomTextField(
                "Favourite Music",
                musicController,
                readOnly: false,
              ),
            ),
            // ///TODO REPLACE EMAIL
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: paddingRes30, vertical: 8),
              child: _buildCustomTextField(
                "Favourite Band",
                bandController,
                readOnly: false,
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: paddingRes30, vertical: 8),
              child: _buildCustomTextField(
                "Favourite Book",
                bookController,
                readOnly: false,
              ),
            ),

            const SizedBox(
              height: 20,
            ),
            // ElevatedButton(
            //     onPressed: () async {
            //       profileController.saveInfo(
            //           hobby: hobbyController.text,
            //           music: musicController.text,
            //           imageUrl: userMap['imageUrl'], book: bookController.text, band: bandController.text);
            //     },
            //     child: const Text('Save')),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController textEditingController, {
    bool readOnly = true,
  }) {
    return TextFormField(
      controller: textEditingController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: hintText,
        hintStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        disabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(30)),

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

  Future<void> _handlePressed(BuildContext context) async {
    setState(() {
      chatLoading = true;
    });

    final navigator = Navigator.of(context);
    print("other user: ${widget.otherUser}");
    final room = await FirebaseChatCore.instance.createRoom(widget.otherUser);

    // navigator.pop();

    setState(() {
      chatLoading = false;
    });

    await navigator.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: room,
        ),
      ),
    );
  }

  Future<void> _onLocationPressed() async {
    setState(() {
      locationLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      Get.snackbar("Request Failed", "Enable service Location");
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

        Get.snackbar("Request Failed", "Location permission denied", backgroundColor: Colors.white);

        setState(() {
          locationLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      Get.snackbar("Request Failed",
          "Location permissions are permanently denied, we cannot request permissions. Enable from app settings",backgroundColor: Colors.white);

      setState(() {
        locationLoading = false;
      });

      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    await CurrentUserInfo.getCurrentUserMapFresh();
    locationLoading = false;

    Map metadata =   widget.otherUser.metadata ?? {};
    Map positionMap = metadata['Position'];



    setState(() {
      locationLoading = false;
    });

    Get.to(() => GoogleMapScreen(myCurrentPosition: position, preferredPosition: LatLng(positionMap['lat'], positionMap['long'],), users: [widget.otherUser],userSelected: true, ));
  }

}
