import 'package:circle/screens/posts/add_post_screen.dart';
import 'package:circle/screens/posts/news_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SelectCircleForPosts extends StatelessWidget {
  const SelectCircleForPosts({Key? key}) : super(key: key);

  ///otherwise to create posts

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Select Circle"),
      ),
      body: Padding(
        padding:  EdgeInsets.only(right: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            15.verticalSpace,
            Padding(
              padding:  EdgeInsets.only(left: 20.w),
              child: Text( "Select a circle to view or add a new a post" ,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold

              ),
              ),
            ),
            30.verticalSpace,
            Expanded(
          child: StreamBuilder<List<types.Room>>(
              stream: FirebaseChatCore.instance.rooms(),
          initialData: const [],
          builder: (context,AsyncSnapshot<List<types.Room>> snapshot) {
            // print("Hiragino Kaku Gothic ProN");
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                // alignment: Alignment.center,
                // margin: const EdgeInsets.only(
                //   bottom: 200,
                // ),
                // child: const Text('No Circles'),
              );
            }

            try{
              snapshot.data!
                  .sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
            }
            catch(e){
              for (var element in snapshot.data!) {print(element.updatedAt);}
            }

            return ListView.builder(

              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final types.Room room = snapshot.data![index];

                // print("room type :${room.type}");

                if( ((room.metadata == null) || (room.metadata!["isChildCircle"] == null) || (room.metadata!["isChildCircle"] == false)) && (room.type == (types.RoomType.group)) ){
                  return InkWell(
                    onTap: () {

                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildAvatar1(room),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10,),
                                    const SizedBox(height: 4),
                                    Text(
                                      room.name ?? 'no name',
                                      style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ),
                              10.horizontalSpace,
                              ElevatedButton(onPressed: (){
                                Get.to(()=>NewsFeedScreen(groupRoom: room));
                              }, child: const Text("View")

                              ),
                              15.horizontalSpace,

                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green
                                  ),
                                  onPressed: (){
                                  Get.to(()=>AddPostScreen(groupRoom: room,goToPostsPage : true));
                                  }, child: const Text( "Add")

                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            );
          },
    ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar1(types.Room room) {
    var color = Colors.transparent;

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      margin: const EdgeInsets.only(right: 0),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
        radius: 30,
        child: !hasImage
            ? Text(
          name.isEmpty ? '' : name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        )
            : null,
      ),
    );
  }

}
