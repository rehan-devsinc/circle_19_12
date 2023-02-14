import 'package:cached_network_image/cached_network_image.dart';
import 'package:circle/models/post_model.dart';
import 'package:circle/screens/posts/add_post_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/news_feed_controller.dart';
import '../../globals/global_functions.dart';
import '../other_user_profile.dart';
import '../profile_screen.dart';

class NewsFeedScreen extends StatelessWidget {
  NewsFeedScreen({Key? key, required this.groupRoom}) : super(key: key);

  final types.Room groupRoom;

  final NewsFeedController newsFeedController = NewsFeedController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title:  Text("Posts in ${groupRoom.name}"),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where("circleId", isEqualTo: groupRoom.id).orderBy('createdAt',descending: true)
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (!(snapshot.hasData) ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }


            final List<PostModel> posts = snapshot.data!.docs
                .map((e) => PostModel.fromJson(e.data()))
                .toList();

            newsFeedController.fillList(posts.length);

            if(posts.isEmpty){
              return const Center(
                child: Text("Nothing to show"),
              );
            }


            return ListView.separated(
              separatorBuilder: (context, index){
                if(index==(posts.length-1)){
                  return SizedBox();
                }
                return Divider();

              },
              padding: EdgeInsets.only(top: 12.h),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(posts[index].authorId)
                          .get(),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                              snapshot) {
                        if (!(snapshot.hasData) ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return  SizedBox(
                            height: posts[index].picturesList.isNotEmpty ? 0.6.sh : 0.1.sh,
                          );
                        }

                        return buildPostWidget(
                            snapshot.data!.data()!, posts[index],listItemIndex: index,userId: posts[index].authorId,newsFeedController: newsFeedController );
                      });
                });
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(()=>AddPostScreen(groupRoom: groupRoom));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}

Widget buildPostWidget(Map<String, dynamic> userMap, PostModel post,{required int listItemIndex, required String userId, required NewsFeedController newsFeedController}) {

  return Padding(
    padding:  EdgeInsets.only(bottom: 12.h),
    child: Material(
      elevation: 0,
      // color: Colors.green,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
        child: Column(

          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:  EdgeInsets.only(left: 12.w, right: 12.w ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: (){
                          if(userId == FirebaseAuth.instance.currentUser!.uid){
                            Get.to(()=>ProfileScreen());
                          }
                          else {
                            Get.to(() => OtherUserProfileScreen(
                              otherUser: getUserFromMap(userMap,userId),
                            ));
                          }

                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(userMap['imageUrl']),
                              radius: 20.r,
                            ),
                            10.horizontalSpace,
                            Padding(
                              padding: EdgeInsets.only(bottom: 5.h),
                              child: Text(userMap['firstName'] + " " + userMap['lastName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(timeago.format(post.createdAt),style: TextStyle(fontSize: 12.sp),),

                    ],
                  ),
                  (post.text!=null && post.text!.isNotEmpty) ? Padding(

                    padding:  EdgeInsets.only(top: 12.h, left: 4.w),
                    child: Text(post.text!, style: TextStyle(fontSize: 18.sp),),
                  ) : const SizedBox(),

                ],
              ),
            ),
            5.verticalSpace,
            if(post.picturesList.isNotEmpty)
              SizedBox(
                height: 0.5.sh,
                width: 1.sw,
                child: PageView.builder(
                    controller: PageController(initialPage: newsFeedController.currentIndexList[listItemIndex].value ),
                    onPageChanged: (index){
                      newsFeedController.modifyIndex(index,listItemIndex: listItemIndex);
                    },
                    scrollDirection: Axis.horizontal,
                    itemCount: post.picturesList.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        width: 1.sw,
                        height: 0.5.sh,
                        fit: BoxFit.cover,
                        imageUrl: post.picturesList[index],
                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                            SizedBox(
                                height: 30.h,
                                child: Center(child: CircularProgressIndicator(value: downloadProgress.progress))),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      );

                      return Image.network(
                        post.picturesList[index],
                        width: 1.sw,
                        height: 0.5.sh,
                        fit: BoxFit.cover,
                      );
                    }),
              ),
            10.verticalSpace,

            // Icon(Icons.add_a_photo, size: 50,),
            // Icon(Icons.add_a_photo, size: 50,),
            // Icon(Icons.add_a_photo, size: 50,),


            if (post.picturesList.length > 1)
              VariableDots(
                  listItemIndex: listItemIndex,
                  imagesCount: post.picturesList.length,
                  newsFeedController: newsFeedController),

          ],
        ),
      ),
    ),
  );
}


class VariableDots extends StatelessWidget {
  const VariableDots(
      {Key? key, required this.imagesCount, required this.newsFeedController, required this.listItemIndex})
      : super(
          key: key,
        );

  final int imagesCount;
  final NewsFeedController newsFeedController;
  final int listItemIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.h,
      child: ListView.builder(
        padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: imagesCount < 6 ? imagesCount : 5,
          shrinkWrap: true,
          itemBuilder: (context, i) {
            return Padding(
              padding:  EdgeInsets.only(right: 5.w),
              child: Obx(() => _buildDot(
                  active: i == newsFeedController.currentIndexList[listItemIndex].value
                      ? true
                      : false)),
            );
          }),
    );
  }

  Widget _buildDot({bool active = false}) {
    return Icon(Icons.circle,
        color: active ? Colors.pink : Colors.grey.withOpacity(0.2),
      size: 10.h,

    );
  }
}
