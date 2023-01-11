import 'package:circle/logoutController.dart';
import 'package:circle/phone_login/phone_login.dart';
import 'package:circle/screens/buttons_screens/circle_buttons_screens.dart';
import 'package:circle/screens/buttons_screens/event_buttons_screens.dart';
import 'package:circle/screens/chat_core/search_chat_screen.dart';
import 'package:circle/screens/chat_core/search_users.dart';
import 'package:circle/screens/chat_core/users.dart';
import 'package:circle/screens/new_chat_screen.dart';
import 'package:circle/screens/profile_screen.dart';
import 'package:circle/screens/view_circle_page.dart';
import 'package:circle/userinfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:circle/screens/Create_Circle_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../notification_service/local_notification_service.dart';
import '../utils/db_operations.dart';
import '../utils/new_user_config.dart';
import '../widgets/LocationSharingWidget.dart';
import 'buttons_screens/profile_buttons_screen.dart';
import 'chat_core/rooms.dart';
import 'chat_core/view_requests_page.dart';
import 'google_maps_screen.dart';
import 'package:flutter_switch/flutter_switch.dart';

class MainCircle extends StatefulWidget {
  const MainCircle({Key? key}) : super(key: key);
  @override
  State<MainCircle> createState() => MainCircleState();
}

class MainCircleState extends State<MainCircle> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey1 = new GlobalKey<ScaffoldState>();

  int index = 0;
  @override
  State<MainCircle> createState() => MainCircleState();

  void viewMyCircles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const viewCircle()),
    );
  }

  checkUser() async {
    try {
      if (!((await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()))
          .exists) {
        Get.offAll(() => const PhoneLoginScreen());
      }
    } catch (e) {}
  }

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      print("current user is null");
      Get.offAll(() => const PhoneLoginScreen());
    } else {
      checkUser();
      print("current user is not null");
    }

    super.initState();

    /// 1. This method call when app in terminated state and you get a notification
    /// when you click on notification app open from terminated state and you can get notification data in this method

    FirebaseMessaging.instance.getInitialMessage().then(
      (message) {
        print("FirebaseMessaging.instance.getInitialMessage");
        if (message != null) {
          print("New Notification");
          print(message.notification?.title);
          print(message.notification?.body);
          print("notification data: ${message.data}");

          if ((message.notification?.title?.toLowerCase().contains("invite") ??
                  false) ||
              (message.notification?.body?.toLowerCase().contains("invite") ??
                  false)) {
            Get.to(const ViewRequestsPage());
          }

          // if (message.data['_id'] != null) {
          //   Navigator.of(context).push(
          //     MaterialPageRoute(
          //       builder: (context) => DemoScreen(
          //         id: message.data['_id'],
          //       ),
          //     ),
          //   );
          // }
        }
      },
    );

    /// 2. This method only call when App in forground it mean app must be opened
    FirebaseMessaging.onMessage.listen(
      (message) {
        print("FirebaseMessaging.onMessage.listen");
        if (message.notification != null) {
          print(message.notification!.title);
          print(message.notification!.body);
          print("message.data11 ${message.data}");
          LocalNotificationService.createanddisplaynotification(message);
          if ((message.notification?.title?.toLowerCase().contains("invite") ??
                  false) ||
              (message.notification?.body?.toLowerCase().contains("invite") ??
                  false)) {
            print("contains invite word");
            Get.to(const ViewRequestsPage());
          }
        }
      },
    );

    /// 3. This method only call when App in background and not terminated(not closed)
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        print("FirebaseMessaging.onMessageOpenedApp.listen");
        if (message.notification != null) {
          print(message.notification!.title);
          print(message.notification!.body);
          print("message.data22 ${message.data}");
          if ((message.notification?.title?.toLowerCase().contains("invite") ??
                  false) ||
              (message.notification?.body?.toLowerCase().contains("invite") ??
                  false)) {
            Get.to(const ViewRequestsPage());
          }
        }
      },
    );

    if (FirebaseAuth.instance.currentUser != null) {
      if ((FirebaseAuth.instance.currentUser!.metadata.creationTime!
              .difference(
                  FirebaseAuth.instance.currentUser!.metadata.lastSignInTime!)
              .inMinutes <
          1)) {
        NewUserConfigurations().setupUserScheduledInvites();
      }
    }

    CurrentUserInfo.getCurrentUserMapFresh();
  }

  int _currentIndex = 0;

  final LogOutController logOutController = LogOutController();

  Map<String, dynamic>? userMap;
  Map metadata = {};

  @override
  Widget build(BuildContext context) {
    // print(FirebaseAuth.instance.currentUser!.metadata.creationTime);
    // print(FirebaseAuth.instance.currentUser!.metadata.lastSignInTime);
    //
    // print(FirebaseAuth.instance.currentUser!.uid);
    // print(FirebaseChatCore.instance.firebaseUser);

    // TODO: implement build
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          key: _scaffoldKey1,
          drawer: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      snapshot) {
                userMap = snapshot.data?.data();
                metadata = userMap?['metadata'] ?? {};
                if (userMap != null) {
                  CurrentUserInfo.userMap = userMap;
                  metadata = userMap!['metadata'];
                }

                return Drawer(
                  child: Container(
                    color: Colors.blue,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          padding: EdgeInsets.zero,
                          child: UserAccountsDrawerHeader(
                            margin: EdgeInsets.zero,
                            accountName: userMap == null
                                ? Text('username')
                                : Text(
                                    "${userMap!["firstName"]} ${userMap!["lastName"]}"),
                            accountEmail: Text(metadata['user_id'] ?? ""),
                            currentAccountPicture: userMap == null
                                ? null
                                : CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(userMap!["imageUrl"]),
                                  ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.home,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Home",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Get.off(const MainCircle());
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.search_circle_fill,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Search Circles",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.to(const SearchChatScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.search,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Search Users",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.to(const SearchUsersScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Create a Circle",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.to(CreateCirclePage());
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.person_2,
                            color: Colors.white,
                          ),
                          title: const Text(
                            "Select Users",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.to(UsersPage());
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Log Out",
                            textScaleFactor: 1.2,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () async {
                            Get.back();
                            await logout();
                          },
                        )
                      ],
                    ),
                  ),
                );
              }),
          // backgroundColor: Colors.lightBlue,
          appBar: AppBar(
            elevation: 10.0,
            shadowColor: Colors.white70,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.0),
                bottomRight: Radius.circular(40.0),
              ),
              side: BorderSide(width: 0.7),
            ),
            title: const Text(
              'Circle',
              style: TextStyle(
                  fontSize: 25.0, fontFamily: 'Lora', letterSpacing: 1.0),
            ),
            bottom: _bottom(),
            actions: [
              InkWell(
                onTap: () {
                  // print("Hiragino Kaku Gothic ProN");
                  Get.to(const SearchChatScreen());
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Icon(
                    CupertinoIcons.search_circle,
                    size: 25.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(
                      CupertinoIcons.refresh_circled,
                      size: 25.0,
                    ),
                    onPressed: () async {
                      Get.offAll(() => const MainCircle());
                      // print('Clicked Refresh in Main Window');
                    }),
              ),
            ],
          ),
          body: (_currentIndex == 1)
              ? const RoomsPage(
                  secondVersion: true,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 25,),
                      const LocationSharingWidget(),


                      Expanded(
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: 100,),
                            ElevatedButton(
                              child: const Text("TEXT"),
                              onPressed: () {
                                Get.to(()=>NewChatTabsScreen());
                                // viewMyCircles(context);
                              },
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(80, 80),
                                shape: const CircleBorder(),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(

                                    ///VIEW CIRCLE INVITES REPLACEMENT
                                    child: const Text("PROFILE"),
                                    onPressed: () {
                                      Get.to(()=>ProfileScreen());
                                      // Get.to(const ProfileButtonsScreen());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: Size(100, 80),
                                      shape: CircleBorder(),
                                    )),
                                Obx(() => ElevatedButton(

                                    ///VIEW CIRCLE INVITES REPLACEMENT
                                    child: mainScreenController.locationLoading.value
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text("My Location"),
                                    onPressed:
                                        mainScreenController.locationLoading.value
                                            ? () {}
                                            : () async {
                                                await _onLocationPressed();
                                              },
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: Size(130, 130),
                                      shape: CircleBorder(),
                                    ))),
                                ElevatedButton(

                                    ///VIEW CIRCLE INVITES REPLACEMENT
                                    child: const Text("CIRCLES"),
                                    onPressed: () {
                                      Get.to(const CircleButtonScreens());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: Size(100, 80),
                                      shape: CircleBorder(),
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            ElevatedButton(

                                ///VIEW CIRCLE INVITES REPLACEMENT
                                child: const Text("EVENTS"),
                                onPressed: () {
                                  Get.to(EventButtonsScreen());
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(100, 80),
                                  shape: CircleBorder(),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ));
  }

  MainScreenController mainScreenController = MainScreenController();

  Future<void> _onLocationPressed() async {
    mainScreenController.locationLoading.value = true;
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

        mainScreenController.locationLoading.value = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      Get.snackbar("Request Failed",
          "Location permissions are permanently denied, we cannot request permissions. Enable from app settings",backgroundColor: Colors.white);

      mainScreenController.locationLoading.value = false;

      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    await CurrentUserInfo.getCurrentUserMapFresh();
    mainScreenController.locationLoading.value = false;

    Get.to(() => GoogleMapScreen(myCurrentPosition: position));
  }

  Future<void> logout() async {
    print('hi');

    logOutController.loading.value = true;

    try {
      String fcmToken = await DBOperations.getDeviceTokenToSendNotification();
      // List<String> tokenList = [fcmToken];

      if (userMap == null) {
        DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get();
        userMap = documentSnapshot.data()!;
      }

      Map metadata = userMap!['metadata'];

      List previousTokens = metadata['fcmTokens'];
      previousTokens.removeWhere((dynamic element) {
        return element.toString() == fcmToken.toString();
      });

      metadata['fcmTokens'] = previousTokens;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"metadata": metadata});
    } catch (e) {
      print(e);
      rethrow;
    }

    await FirebaseAuth.instance.signOut();

    logOutController.loading.value = false;
    CurrentUserInfo.userMap = null;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return PhoneLoginScreen();
    }));
  }

  PreferredSizeWidget? _bottom() {
    return TabBar(
      indicatorPadding: EdgeInsets.only(left: 20.0, right: 20.0),
      labelColor: Colors.blueGrey,
      unselectedLabelColor: Colors.white70,
      indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.0, color: Colors.black87),
          insets: EdgeInsets.symmetric(horizontal: 15.0)),
      automaticIndicatorColorAdjustment: true,
      labelStyle: const TextStyle(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
      ),
      onTap: (index) {
        // print("\nIndex is:$index");
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      tabs: const [
        Tab(
          child: Text(
            'Home Page',
            style: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Lora',
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Tab(
          child: Text(
            'Chats',
            style: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Lora',
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class NavigationBarItem extends StatelessWidget {
  const NavigationBarItem({
    Key? key,
    required this.label,
    required this.icon,
  }) : super(key: key);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: () {
        // print('context');
      },
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(
              height: 8,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreenController extends GetxController {
  Rx<bool> locationLoading = false.obs;
}

