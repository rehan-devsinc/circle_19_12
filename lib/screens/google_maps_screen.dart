import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:circle/models/user_location.dart';
import 'package:circle/userinfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

class GoogleMapScreen extends StatefulWidget {
  GoogleMapScreen({Key? key, required this.currentPosition}) : super(key: key);
  final Position currentPosition;

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  final List<MarkerData> markers = [];
  final List<Polyline> _polylines = [];

  ///gotcha key
  // String key = "AIzaSyCWsGrUuzgLzaLQVsS5g6Q-lfOhiz96NcY";

  ///circle key
  String key = "AIzaSyDaFhrAJBKl4gWcohHREToUHnOpbRUgOGM";

  @override
  void initState() {
    // TODO: implement initState

     shareLocation();

    super.initState();
  }

  Future<void> shareLocation() async{
    await FirebaseFirestore.instance.collection('Locations').doc(FirebaseAuth.instance.currentUser!.uid).set(
      UserLocationAndImage(lat: widget.currentPosition.latitude, lng: widget.currentPosition.longitude, imgUrl: CurrentUserInfo.userMap!['imageUrl']).toMap()
    );
  }

  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("My Location"),
      ),
      body: FutureBuilder(
        future: getAllMarkers(),
        builder: (context,AsyncSnapshot<List<MarkerData>> snapshot) {

          if(!snapshot.hasData || snapshot.connectionState==ConnectionState.waiting){
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.teal,
                ),
                SizedBox(height: 10,),
                Text("Fetching available users locations")
              ],
            ));
          }

          return CustomGoogleMapMarkerBuilder(
            // screenshotDelay: Duration(seconds: 1),
            customMarkers: snapshot.data!,
            builder: (BuildContext context, Set<Marker>? markers) {
              if(markers==null || markers.isEmpty){
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude),
                  zoom: 14.4746,
                ),
                markers: markers ?? {},
                polylines: _polylines.toSet(),
                onMapCreated: (GoogleMapController controller) { },
              );
            },
          );
        }
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
    Map directions =  await getDirections(LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude), LatLng(widget.currentPosition.latitude+0.5, widget.currentPosition.longitude+0.5));

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

  Future<Uint8List> getNetworkImageBytes(String imgUrl) async{
    http.Response response = await http.get(
      Uri.parse(imgUrl)
    );
    return response.bodyBytes;
  }

  Future<List<MarkerData>> getAllMarkers() async{
    markers.clear();
    List<UserLocationAndImage> locations = [];

    QuerySnapshot<Map<String,dynamic>> querySnapshot = await FirebaseFirestore.instance.collection('Locations').get();

    querySnapshot.docs.removeWhere((element) => element.id==FirebaseAuth.instance.currentUser!.uid);

    for (var doc in querySnapshot.docs) {
      locations.add(UserLocationAndImage.fromMap(doc.data()));
    }

    locations.add(UserLocationAndImage(lat: widget.currentPosition.latitude, lng: widget.currentPosition.longitude, imgUrl: CurrentUserInfo.userMap!['imageUrl']));


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


    return markers;
  }

}