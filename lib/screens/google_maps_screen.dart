import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:circle/models/user_location.dart';
import 'package:circle/userinfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

import '../gmaps_screen_controller.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({Key? key, required this.myCurrentPosition,  this.users, this.userSelected=false, this.preferredPosition}) : super(key: key);
  final Position myCurrentPosition;
  final List<types.User>? users;
  final bool userSelected;
  final LatLng? preferredPosition;

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  final List<MarkerData> markers = [];
  final List<Polyline> _polylines = [];
  List<types.User> _users = [];

  late GoogleMapsScreenController controller;

  GoogleMapController? googleMapController;

  ///gotcha key
  // String key = "AIzaSyCWsGrUuzgLzaLQVsS5g6Q-lfOhiz96NcY";

  ///circle key
  String key = "AIzaSyDaFhrAJBKl4gWcohHREToUHnOpbRUgOGM";

  @override
  void initState() {
    controller = GoogleMapsScreenController(firstUserSelected: widget.userSelected);
    // TODO: implement initState

     shareLocation();

    super.initState();
  }

  Future<void> shareLocation() async{
    Map userMap = CurrentUserInfo.userMap ?? (await CurrentUserInfo.getCurrentUserMapFresh());
    Map userMetadata = userMap['metadata'] ?? {};
    userMetadata['locationSharing'] = true;
    userMetadata['Position'] = {
      'lat' : widget.myCurrentPosition.latitude,
      'long' : widget.myCurrentPosition.longitude
    };

    FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'metadata' : userMetadata}
    );
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Users Location"),
      ),
      body: FutureBuilder(
        future: getAllMarkersAndUsers(),
        builder: (context,AsyncSnapshot<List<MarkerData>> snapshot) {

          if(!snapshot.hasData || snapshot.connectionState==ConnectionState.waiting){
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children:  [
                const CircularProgressIndicator(
                  color: Colors.teal,
                ),
                const SizedBox(height: 10,),
                Text(widget.users != null ? "Fetching Location" : "Fetching available users locations")
              ],
            ));
          }

          return SizedBox(
            child: Stack(
              children: [
                CustomGoogleMapMarkerBuilder(
                  // screenshotDelay: Duration(seconds: 1),
                  customMarkers: snapshot.data!,
                  builder: (BuildContext context, Set<Marker>? markers) {
                    if(markers==null || markers.isEmpty){
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return GoogleMap(

                      // myLocationButtonEnabled: true,
                   // myLocationEnabled: true,
                    zoomControlsEnabled: false,

                    initialCameraPosition: CameraPosition(
                    target: (widget.preferredPosition!=null) ? LatLng(widget.preferredPosition!.latitude, widget.preferredPosition!.longitude) : LatLng(widget.myCurrentPosition.latitude, widget.myCurrentPosition.longitude),
                    zoom: 19,
                    ),
                    markers: markers ?? {},
                    polylines: _polylines.toSet(),
                    onMapCreated: (GoogleMapController controller) {
                      googleMapController = controller;
                    },
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: SizedBox(
                    height: 140,
                    width: Get.width,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20) )
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                      width: Get.width,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _users.length,
                          itemBuilder: (context,index){
                            types.User _user = _users[index];
                            Map metadata = _user.metadata ?? {};
                            LatLng? latLng;
                            Map positionMap = metadata['Position'] ?? {};
                            if((positionMap['lat']!=null) && (positionMap['long']!=null) ){
                              latLng = LatLng(positionMap['lat'], positionMap['long']);
                            }

                            return Obx(() => Padding(
                              padding: EdgeInsets.only(left: index== 0 ? 20.0 : 0, right: index==(_users.length-1) ? 20 : 0),
                              child: buildUserAvatar(_users[index],
                                  selected: index==(controller.selectedIndex.value),
                                  index: index,
                                  enabled: (metadata['locationSharing'] ?? false),
                              latlng: latLng
                              ),
                            ));
                          }),
                    ),
                  ),
                ),

              ],
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          if(googleMapController!=null){
            googleMapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(widget.myCurrentPosition.latitude, widget.myCurrentPosition.longitude,),zoom: 12)));

          }
        },
        child: const Icon(Icons.my_location_outlined),
      ),
    );
  }

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {

    print("into get directions");


    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$key';

    print("fetching response ");


    var response = await http.get(Uri.parse(url));

    print("response success");

    //print(response);

    var json = jsonDecode(response.body);
    print("decoded json");
    print(json);


    List <PointLatLng> list = PolylinePoints()
        .decodePolyline(json['routes'][0]['overview_polyline']['points']);

    print("decoded points list");


    var results = {
      'bounds_ne': json['routes'][0]['bounds']['northeast'],
      'bounds_sw': json['routes'][0]['bounds']['southwest'],
      'start_location': json['routes'][0]['legs'][0]['start_location'],
      'end_location': json['routes'][0]['legs'][0]['end_location'],
      'polyline': json['routes'][0]['overview_polyline']['points'],
      'polyline_decoded': list

    };
    print(" get directions ended");


    return results;
  }

  Future<List<Polyline>> _setPolyline() async{

    print("into set polylines");
    Map directions =  await getDirections(LatLng(widget.myCurrentPosition.latitude, widget.myCurrentPosition.longitude), LatLng(widget.myCurrentPosition.latitude+0.5, widget.myCurrentPosition.longitude+0.5));

    List<PointLatLng> points = directions['polyline_decoded'];

    print("polyline points length: ${points.length}");
    _polylines.add(
        Polyline(
        polylineId: const PolylineId("abc"),
        width: 2,
        color: Colors.blue,
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList()));

    return _polylines;
  }

  Widget buildUserAvatar(types.User user, {bool selected = false, required int index, required bool enabled, LatLng? latlng}){

    return InkWell(
      onTap: enabled ? (){
        controller.selectedIndex.value = index;
        googleMapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(latlng!.latitude, latlng.longitude),zoom: 10)));
      } : null,
      child: Padding(
        padding: const EdgeInsets.only(right: 15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CircleAvatar(

                    backgroundImage: NetworkImage(user.imageUrl!, ) ,
                    radius: 30,
                    foregroundColor: Colors.grey,

                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:  (selected && (enabled)) ? Colors.orange : Colors.transparent,
                      width: 5
                    )
                  ),
                ),
                // const Positioned(
                //     top: 0,
                //     right: 0,
                //     child: Icon(Icons.close, color: Colors.red, size: 30,))
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.firstName ?? "no first name", style:  TextStyle(fontWeight: FontWeight.bold, color: enabled ? null :  Colors.grey), ),
                // SizedBox(width: 4,),
                enabled ? const SizedBox() : const Icon(Icons.close, size: 15, color: Colors.red,)
              ],
            )
          ],
        ),
      ),
    );

  }

  List<types.User> rearrangeUsers(List<types.User> users){
    List<types.User> allUsers = List.from(users);
    List<types.User> arrangedUsers = [];
    print("users length: ${allUsers.length}");

    for (var user in users){

      print("loop started for user ${user.firstName}");
      // print("username : ${user.firstName}");
      Map metadata = user.metadata ?? {};
      if (metadata['locationSharing'] ?? false){
        allUsers.removeWhere((u)=>(u.id==user.id));
        arrangedUsers.add(user);
      }
      print("all users length: ${allUsers.length}");
      print("loop completed for user ${user.firstName}");
    }

    arrangedUsers.addAll(allUsers);
    print("returning arranged users");
    return arrangedUsers;
  }

  Future<Uint8List> getNetworkImageBytes(String imgUrl) async{
    http.Response response = await http.get(
      Uri.parse(imgUrl)
    );
    return response.bodyBytes;
  }

  Future<List<MarkerData>> getAllMarkersAndUsers() async{

    // return markers;

    markers.clear();

    _users.clear();

    if(widget.users!=null){
      _users = widget.users!;
    }
    else
    {
      _users = (await FirebaseChatCore.instance.users().first);
    }


    if(_users.isEmpty){
      print("users are empty");
    }

    print("hi");

    _users = rearrangeUsers(_users);

    List<UserLocationAndImage> locations = [];

    print("users length: ${_users.length}");
    for (var user in _users) {
      print("user name: ${user.firstName}");

      Map metadata = user.metadata ?? {};
      if(metadata['locationSharing'] ?? false) {
        Map position = metadata['Position'];
        // print()
        UserLocationAndImage userLocationAndImage =
            UserLocationAndImage(lat: position['lat'], lng: position['long'], imgUrl: user.imageUrl!);
        locations.add(userLocationAndImage);

      }


      print("loop completed");



    }

    print("bye");


    locations.add(UserLocationAndImage(lat: widget.myCurrentPosition.latitude, lng: widget.myCurrentPosition.longitude, imgUrl: CurrentUserInfo.userMap!['imageUrl']));

    for (var element in locations) {

      Uint8List imgBytes = await getNetworkImageBytes(element.imgUrl);

      markers.add(
          MarkerData(
            marker: Marker(  markerId:  MarkerId(element.imgUrl.substring(0,2)), position: LatLng(element.lat, element.lng)),
            child: SizedBox(
              // height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset("assets/images/marker.png", height: 60, width: 60, color: Colors.purple,fit: BoxFit.fill,),
                  Positioned(
                    top: 5,
                    // left: 0,
                    // right: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundImage: MemoryImage(imgBytes),
                      // child: Image.asset("assets/images/user.png", )) :
                    ),
                  ),
                ],
              ),
            ),
          ),
      );
    }

    print("returning");


    return markers;
  }

}