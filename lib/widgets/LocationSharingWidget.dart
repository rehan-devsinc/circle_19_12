import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../screens/google_maps_screen.dart';
import '../userinfo.dart';

class LocationSharingWidget extends StatefulWidget {
  const LocationSharingWidget({Key? key}) : super(key: key);

  @override
  State<LocationSharingWidget> createState() => _LocationSharingWidgetState();
}

class _LocationSharingWidgetState extends State<LocationSharingWidget> {
  bool sharingLocation = false;
  bool loading = false;
  Position? position;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context,AsyncSnapshot<DocumentSnapshot<Map<String,dynamic>>> snapshot){

        if((!(snapshot.connectionState==ConnectionState.waiting)) &&  (snapshot.hasData)){
          DocumentSnapshot<Map<String,dynamic>> documentSnapshot = snapshot.data!;
          Map<String,dynamic> userMap = documentSnapshot.data()!;
          Map userMetadata = userMap['metadata'] ?? {};
          sharingLocation = userMetadata['locationSharing'] ?? false;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Location Sharing ${ sharingLocation ? "Enabled" : "Disabled"}",
                    style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  loading ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(

                    ),
                  ) :
                  FlutterSwitch(
                    value: sharingLocation,
                    onToggle: (v) async{
                      sharingLocation = await _onLocationSharingPressed();
                      setState(() {});
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                  ),
                  // const SizedBox(width: 10,),
                ],
              ),
            ],
          );
        });
  }

  ///returns location sharing status
  Future<bool> _onLocationSharingPressed() async {

    ///disable sharing location
    if(sharingLocation){
      Map userMap = CurrentUserInfo.userMap ?? (await CurrentUserInfo.getCurrentUserMapFresh());
      Map userMetadata = userMap['metadata'] ?? {};
      userMetadata['locationSharing'] = false;
      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'metadata' : userMetadata}
      );
      return false;
    }

    ///enable sharing location

    ///sharing location
    if(position!=null){
      Map userMap = CurrentUserInfo.userMap ?? (await CurrentUserInfo.getCurrentUserMapFresh());
      Map userMetadata = userMap['metadata'] ?? {};
      userMetadata['locationSharing'] = true;
      userMetadata['Position'] = {
        'lat' : position!.latitude,
        'long' : position!.longitude
      };

      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'metadata' : userMetadata}
      );

      return true;
    }

    setState((){
      loading = true;
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
      setState((){
        loading = false;
      });

      return false;
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
        setState((){
          loading = false;
        });


        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      Get.snackbar("Request Failed",
          "Location permissions are permanently denied, we cannot request permissions. Enable from app settings",backgroundColor: Colors.white);


      setState((){
        loading = false;
      });

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    position = await Geolocator.getCurrentPosition();

    Map userMap = CurrentUserInfo.userMap ?? (await CurrentUserInfo.getCurrentUserMapFresh());
    Map userMetadata = userMap['metadata'] ?? {};
    userMetadata['locationSharing'] = true;
    userMetadata['Position'] = {
      'lat' : position!.latitude,
      'long' : position!.longitude
    };

    FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'metadata' : userMetadata}
    );

    setState((){
      loading = false;
    });


    return true;
  }

}
