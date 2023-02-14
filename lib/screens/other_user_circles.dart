import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:get/get.dart';

class OtherUserCircles extends StatefulWidget {
  const OtherUserCircles({Key? key, required this.user}) : super(key: key);
  final types.User user;

  @override
  State<OtherUserCircles> createState() =>
      _OtherUserCirclesState();
}

class _OtherUserCirclesState extends State<OtherUserCircles> {
  List<Map<String, dynamic>> circleMaps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title:  Text("${widget.user.firstName} circles"),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text("No circles to show"),
              );
            }

            circleMaps = snapshot.data!.docs.map((e) {

              Map<String,dynamic> map = Map.from(e.data());
              map['id'] = e.id;

              // print("e.id: ${e.id}");
              // e.data()['id'] = e.id;
              // print(e.data()['id']);
              //
              // e.data().addEntries([
              //   MapEntry('id', e.id)
              // ]);
              // print(map['id']);
              return map;
            }).toList();

            // print(circleMaps.length);

            circleMaps.removeWhere((Map<String,dynamic> map) {
              List userIds = map['userIds'];
             return !(userIds.any((element) => element.toString() == widget.user.id));
            } );

            // print(circleMaps.length);


            return Column(
              children: [
                // ElevatedButton(
                //     child: const Text("Join a Circle by ID"),
                //     onPressed: () async {
                //       await joinCircleById();
                //       // Get.to(AllCirclesScreen());
                //       // viewMyCircles(context);
                //     }),
                // const SizedBox(
                //   height: 20,
                // ),
                // const Text(
                //   "Joining Private Circles require approval by circle manager.",
                //   style: TextStyle(color: Colors.white),
                // ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: circleMaps.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> circleMap =
                        circleMaps[index];
                        if (circleMap["type"] == "group") {
                          return buildCircleContainer(
                              circleMap, circleMaps[index]['id']);
                        }
                        return const SizedBox();
                      }),
                ),
              ],
            );
          }),
    );
  }

  Widget buildCircleContainer(Map<String, dynamic> circleMap, String id) {
    final bool hasImage = circleMap['imageUrl'] != null;
    final String name = circleMap['name'] ?? '';

    List userIds = circleMap['userIds'];
    bool alreadyPart = userIds.contains(FirebaseAuth.instance.currentUser!.uid);

    Map metadata = circleMap['metadata'] ?? {};
    List requests = metadata['userRequests'] ?? [];

    for (var element in requests) {
      element = element.toString();
    }

    bool requestSent =
    requests.contains(FirebaseAuth.instance.currentUser!.uid);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor:
                  hasImage ? Colors.transparent : Colors.pinkAccent,
                  backgroundImage:
                  hasImage ? NetworkImage(circleMap['imageUrl']) : null,
                  radius: 30,
                  child: !hasImage
                      ? Text(
                    name.isEmpty ? '' : name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                      : null,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metadata["privacy"] ?? "null",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    name.isEmpty ? 'no name' : name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                  onPressed: (alreadyPart || requestSent)
                      ? null
                      : () async {
                    await joinCircle(circleMap, id);
                  },
                  child: Text(alreadyPart
                      ? "Joined"
                      : requestSent
                      ? "Request Sent"
                      : "Join"))
            ],
          ),
        ],
      ),
    );
  }

  Future<void> joinCircle(
      Map<String, dynamic> circleMap, String circleId) async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmation'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Are you sure you want to join"),
              Text(
                "${circleMap["name"]!} ?",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  Map metadata = circleMap["metadata"] ?? {};
                  List userRequests = metadata["userRequests"] ?? [];

                  if (metadata['privacy'] == "public" ||
                      metadata['privacy'] == null) {
                    await FirebaseFirestore.instance
                        .collection("rooms")
                        .doc(circleId)
                        .update({
                      "userIds": FieldValue.arrayUnion(
                          [FirebaseAuth.instance.currentUser!.uid])
                    });
                    Navigator.pop(context);
                    Get.snackbar("Success", "Circle Joined.",
                        backgroundColor: Colors.white);
                  } else {
                    userRequests
                        .add(FirebaseAuth.instance.currentUser!.uid);
                    metadata['userRequests'] = userRequests;

                    await FirebaseFirestore.instance
                        .collection("rooms")
                        .doc(circleId)
                        .update({'metadata': metadata});
                    Get.snackbar("Success",
                        "Circle Joining Request Sent to Circle Manager",
                        backgroundColor: Colors.white);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Confirm"))
          ],
        ));
  }

}
