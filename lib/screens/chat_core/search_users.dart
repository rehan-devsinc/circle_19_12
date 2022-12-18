import 'package:circle/screens/chat_core/search_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import 'chat.dart';
import 'util.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key, this.onlyFriends = false}) : super(key: key);

  final bool onlyFriends ;

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {


  final FocusNode _focusNode = FocusNode();

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // executes after build
    });

    return
      Scaffold(
        body: SafeArea(
          child: Scaffold(
            appBar: AppBar(title:  Text( widget.onlyFriends ? "Search Friends" : "Search Users"),),
            body: Column(
              children: [
                const SizedBox(height: 25,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextFormField(
                    focusNode: _focusNode,
                    onChanged: (value){
                      setState((){});
                    },
                    controller: searchController,
                    decoration:  InputDecoration(
                        enabledBorder: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(),
                        labelText: widget.onlyFriends ? "Search Friends" : "Search Users",
                        isDense: true
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Expanded(
                  child: StreamBuilder<List<types.User>>(
                    stream: FirebaseChatCore.instance.users(),
                    initialData: const [],
                    builder: (context, AsyncSnapshot<List<types.User>> snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                            bottom: 200,
                          ),
                          child:  Text( widget.onlyFriends ? "No Friends To Show" :'No users'),
                        );
                      }
                      snapshot.data!.removeWhere((element){
                        Map<String, dynamic> metadata = element.metadata ?? {};

                        print('id : ${element.id}, name: ${element.firstName}');
                        print(metadata);
                        // if(element.firstName=="Zoe") {
                        //   return false;
                        // }
                        List friendIds = metadata['friends'] ?? [];
                        for (var element in friendIds) {element=element.toString();}

                        bool isFriend = friendIds.contains(FirebaseAuth.instance.currentUser!.uid);
                        return (!(isFriend));
                      } );

                      print(snapshot.data!);

                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final user = snapshot.data![index];

                          if (searchController.text.isEmpty || user.firstName!.toLowerCase().startsWith(RegExp(searchController.text.toLowerCase().trim()))) {
                            return GestureDetector(
                              onTap: () {
                                _handlePressed(user, context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    _buildAvatar(user),
                                    Text(getUserName(user)),
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

  void _handlePressed(types.User otherUser, BuildContext context) async {
    final navigator = Navigator.of(context);
    print("other user: $otherUser");
    final room = await FirebaseChatCore.instance.createRoom(otherUser);

    navigator.pop();
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: room,
        ),
      ),
    );
  }
}

