import 'package:circle/screens/Create_Circle_screen.dart';
import 'package:circle/screens/chat_core/search_chat_screen.dart';
import 'package:circle/screens/chat_core/search_users.dart';
import 'package:circle/screens/chat_core/users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:get/get.dart';
import 'calendar_list_events.dart';
import 'chat_core/chat.dart';
import 'chat_core/util.dart';
import 'other_user_profile.dart';


class NewChatTabsScreen extends StatelessWidget {
  NewChatTabsScreen({Key? key}) : super(key: key);



  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text('Text',style: TextStyle(color: Colors.black),),
              backgroundColor: Colors.transparent,
              leading: InkWell(
                  onTap: (){
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back, color: Colors.black,)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: InkWell(
                      onTap: (){
                        if((DefaultTabController.of(context)!.index == 0) ) {
                          Get.to(()=>const SearchUsersScreen());
                        }
                        else if (DefaultTabController.of(context)!.index == 1){
                          Get.to(()=>const SearchChatScreen());

                        }
                        else{
                          Get.to(()=>const SearchUsersScreen(onlyFriends: true,));

                        }
                      },
                      child: const Icon(Icons.search_outlined, color: Colors.black,)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: InkWell(
                      onTap: (){
                        Get.to(()=>CalendarListEventsScreen(circleId: 'global',));
                      },
                      child: const Icon(Icons.calendar_month, color: Colors.black,)),
                ),
              ],

            ),
            backgroundColor: Colors.white,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text("Text", style: TextStyle(color: Colors.black),),
                const SizedBox(height: 10,),

                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: SizedBox(
                    width: Get.width*0.75,
                    child: TabBar(

                      onTap: (index){
                        selectedTab = index;
                        print("selected tab is $selectedTab");

                      },
                      indicatorPadding: EdgeInsets.only(top: 40),
                        tabs: [
                      Tab(
                        child: Text("Users", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      Tab(
                        child: Text("Circles", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                      ),
                      Tab(
                        child: Text("Friends", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                      ),


                    ]),
                  ),
                ),
                SizedBox(height: 30,),
                Expanded(child:             TabBarView(children:

                [
                  _buildUsersTabBody(),
                  _buildCirclesTabBody(),
                  _buildFriendsTabBody(),

                ]
                )
                )

              ],
            ),
          );
        }
      ),
    );
  }

  final List<types.User> allUsers = [];


  _buildUsersTabBody(){
    // selectedTab = 0;
    // print("selected tab is $selectedTab");
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("All Users"),
           Divider(
          color: Colors.grey.withOpacity(0.5),
            thickness: 1,
            // height: 3,
          ),
          Expanded(child: StreamBuilder<List<types.User>>(
            stream: FirebaseChatCore.instance.users(),
            initialData: const [],
            builder: (context, AsyncSnapshot<List<types.User>> snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(
                    bottom: 200,
                  ),
                  child: const Text('No users'),
                );
              }

              allUsers.clear();
              allUsers.addAll(snapshot.data!);

              // print(snapshot.data!);

              return ListView.builder(
                // shrinkWrap: true,
                // physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data![index];

                  return InkWell(
                    onTap: () {
                      Get.to(OtherUserProfileScreen(otherUser: user));

                      // if(widget.onlyUsers){
                      // }
                      // else {
                      //   _handlePressed(user, context);
                      // }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(user),
                          Text(getUserName(user), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
          )
          // Text("Circles"),
          // Text("Friends"),
        ],
      ),
    );
  }

  _buildCirclesTabBody(){
    // selectedTab = 1;
    // print("selected tab is $selectedTab");
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("My Circles"),
              Spacer(),
              InkWell(
                  onTap: (){
                    Get.to(()=>CreateCirclePage());
                  },
                  child: Icon(Icons.add_circle_outlined,color: Colors.black, ))
            ],
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1.5,
          ),
          Expanded(child: StreamBuilder<List<types.Room>>(
            stream: FirebaseChatCore.instance.rooms(),
            initialData: const [],
            builder: (context,AsyncSnapshot<List<types.Room>> snapshot) {
              // print("Hiragino Kaku Gothic ProN");
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(
                    bottom: 200,
                  ),
                  child: const Text('No Circles'),
                );
              }

              try{
                snapshot.data!
                    .sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
              }
              catch(e){
                // for (var element in snapshot.data!) {print(element.updatedAt);}
              }

              return ListView.builder(
                // shrinkWrap: true,
                // physics: NeverScrollableScrollPhysics(),

                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final types.Room room = snapshot.data![index];

                  // print("room type :${room.type}");

                  if( ((room.metadata == null) || (room.metadata!["isChildCircle"] == null) || (room.metadata!["isChildCircle"] == false)) && (room.type == (types.RoomType.group)) ){
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              room: room,
                              groupChat: room.type == types.RoomType.group,
                            ),
                          ),
                        );
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
                                      room.type == types.RoomType.group ?
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            room.metadata?['status'] ?? ' status',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                fontStyle: FontStyle.italic
                                            ),
                                          ),
                                          // Text(
                                          //   room.metadata?['privacy'] ?? 'undefined',
                                          //   style: const TextStyle(
                                          //       color: Colors.black,
                                          //       fontSize: 14,
                                          //       fontWeight: FontWeight.normal,
                                          //       fontStyle: FontStyle.italic
                                          //   ),
                                          // )
                                        ],
                                      ) : const SizedBox(),
                                      const SizedBox(height: 4),
                                      Text(
                                        room.name ?? 'no name',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox();
                },
              );
            },
          )
          )
          // Text("Circles"),
          // Text("Friends"),
        ],
      ),
    );
  }

  _buildFriendsTabBody(){
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("My Friends"),
            //   Spacer(),
            //   InkWell(
            //       onTap: (){
            //         Get.to(()=>CreateCirclePage());
            //       },
            //       child: Icon(Icons.add_circle_outlined,color: Colors.black, ))
            ],
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1.5,
          ),
          Expanded(child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
            builder: (context,AsyncSnapshot<DocumentSnapshot<Map<String,dynamic>>> snapshot) {
              // print("Hiragino Kaku Gothic ProN");
              if (!snapshot.hasData || snapshot.connectionState==ConnectionState.waiting) {

                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(
                    bottom: 200,
                  ),
                  child: const Text('No Friends to show'),
                );
              }

              Map metadata = (snapshot.data!.data()!)['metadata'] ?? {};

              List friendsIds = metadata['friends'] ?? {};
              for (var element in friendsIds) {
                element = element.toString();
              }

              List<types.User> friends = [];

              for (var element in allUsers) {
                if(friendsIds.contains(element.id)) {
                  friends.add(element);
                }

              }




              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final user = friends[index];

                  return InkWell(
                    onTap: () {
                      Get.to(OtherUserProfileScreen(otherUser: user));

                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(user),
                          Text(getUserName(user), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
          )
          // Text("Circles"),
          // Text("Friends"),
        ],
      ),
    );
  }



  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
        radius: 20,
        child: !hasImage
            ? Text(
          name.isEmpty ? '' : name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        )
            : null,
      ),
    );
  }

  Widget _buildAvatar1(types.Room room) {
    var color = Colors.transparent;

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
        radius: 25,
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

enum MyTab{
  users,
  circles,
  friends
}
