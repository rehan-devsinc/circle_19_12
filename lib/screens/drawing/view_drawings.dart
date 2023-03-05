import 'package:circle/screens/drawing/new_drawing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';

class MyDrawingsList extends StatelessWidget {
  const MyDrawingsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: Text("My Drawings"),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
          builder: (context,AsyncSnapshot<DocumentSnapshot<Map<String,dynamic>>> snapshot){
            if(snapshot.connectionState==ConnectionState.waiting || (!(snapshot.hasData))){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }


            Map userMap = snapshot.data!.data()!;
            Map metadata = userMap['metadata'] ?? {};
            List drawingUrls = metadata['drawingUrls'] ?? [];

            drawingUrls.clear();

            if(drawingUrls.isEmpty){
              return const Center(
                child: Text("No Drawings to Show :)"),
              );
            }

            return ListView.builder(
              itemCount: drawingUrls.length,
                itemBuilder: (context,index){
              return Padding(
                padding:  EdgeInsets.symmetric(vertical: 10.h,horizontal: 20.w),
                child: Image.network(drawingUrls[drawingUrls.length - index -1 ]),
              );
            });

          }),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            Get.to(()=>NewDrawingScreen());
          }),
    );
  }
}
