import 'package:circle/screens/google_maps_screen.dart';
import 'package:circle/screens/other_user_circles.dart';
import 'package:circle/utils/profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../enums/favourites_category.dart';
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

  List<String> fvrtHobbies = [];
  List<String> fvrtMusics = [];
  List<String> fvrtBooks = [];
  List<String> fvrtBands = [];
  Map<String,dynamic> favoritesMap = {};



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

    if(metadata['favorites']!=null){
      favoritesMap = metadata['favorites'];
      fvrtBands = ((favoritesMap[FavouritesCategory.bands.toString()] ?? []) as List).map((e) => e.toString()).toList();
      fvrtBooks = ((favoritesMap[FavouritesCategory.books.toString()] ?? []) as List).map((e) => e.toString()).toList();
      fvrtHobbies = ((favoritesMap[FavouritesCategory.hobbies.toString()] ?? []) as List).map((e) => e.toString()).toList();
      fvrtMusics = ((favoritesMap[FavouritesCategory.musics.toString()] ?? []) as List).map((e) => e.toString()).toList();
    }

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
                  height: 100.h, width: 100.h, fit: BoxFit.cover),
            ),
            20.verticalSpace,
            Text(
              (widget.otherUser.firstName ?? "") +
                  ((widget.otherUser.lastName ?? "")),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          10.verticalSpace,
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
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(150, 40)
                  ),
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
                      fixedSize: const Size(150, 40),
                      backgroundColor: !(isFriend) ? Colors.green : Colors.red),
                )
              ],
            ),
            const SizedBox(
              height: 0,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                  Map metadata =   widget.otherUser.metadata ?? {};
                  if(metadata['locationSharing'] ?? false){
                    _onLocationPressed();
                  }
                  else{
                    Get.snackbar("Request Denied", "User has disabled his location sharing");
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
                ElevatedButton(
                    child: const Text("User Circles",
                        textAlign: TextAlign.center),
                    onPressed: () {
                      Get.to(()=>OtherUserCircles(user: widget.otherUser));
                    },
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(150, 40)
                  ),


                )


                ,
              ],
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
                              "id",
                              style: TextStyle(fontSize: 18),
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
                                fontStyle: FontStyle.italic
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
              height: 10,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildSingleFavouritesSection(context, fvrtHobbies, "Favourite Hobbies", FavouritesCategory.hobbies, 'Hobby'),
                  buildSingleFavouritesSection(context, fvrtBooks, "Favourite Books", FavouritesCategory.books, 'book'),
                  buildSingleFavouritesSection(context, fvrtMusics, "Favourite Music", FavouritesCategory.musics, 'music'),
                  buildSingleFavouritesSection(context, fvrtBands, "Favourite Bands", FavouritesCategory.bands, 'band'),
                ],
              ),
            ),


            const SizedBox(
              height: 20,
            ),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: paddingRes30),
              child: _buildTagsPortion((((widget.otherUser.metadata ?? {})['tags'] ?? []) as List).map((e) => e.toString()).toList(), context),
            ),
            30.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget buildSingleFavouritesSection(BuildContext context,List<String> favourites,String title,FavouritesCategory category,String miniTitle){
    return Padding(
      padding:  EdgeInsets.only(bottom: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),),
            ],
          ),
          10.verticalSpace,
          if(favourites.isEmpty) const Text("NONE",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontStyle: FontStyle.normal)) ,
          Wrap(
            alignment: WrapAlignment.start,
            // runAlignment: WrapAlignment.start,
            // crossAxisAlignment: WrapCrossAlignment.start,
            runSpacing: 10.h,
            spacing: 12.w,
            children: [
              for (var i in favourites) _buildSingleFavouriteItem(i,context,category,favourites,),
            ],
          )



        ],
      ),
    );
  }

  Widget _buildSingleFavouriteItem(String item, BuildContext context,
      FavouritesCategory category, List<String> favorites,
      {void Function()? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.deepOrange, borderRadius: BorderRadius.circular(5.r)),
      ),
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

  Widget _buildTagsPortion(List<String> myTags, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              " Favourite Tags: ",
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
        if (myTags.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 40.w),
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
          )
      ],
    );
  }

  Widget _buildSingleTag(String tag, BuildContext context,) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.pink, borderRadius: BorderRadius.circular(15.r)),
    );
  }


}
