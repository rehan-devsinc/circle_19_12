import 'package:circle/utils/db_operations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class TagsController{

  List<String> myTags = [];
  List<types.User> allUsers = [];
  types.User? myUser;

  Future initiateMatching({Duration? delay}) async{
    print("into initiate matching");

    if(delay!=null){
      await Future.delayed(delay);
    }

    await getMyUser();
    getUsers();

    print("users length: ${allUsers.length}");

    await Future.delayed(const Duration(seconds: 2));

    print("users length after 2 seconds delay: ${allUsers.length}");


    for (var element in allUsers) {
      print(element.firstName);
    }
    await getAllTagsAndProcess();

  }

  void getUsers(){
    Stream<List<types.User>> stream = FirebaseChatCore.instance.users();

    stream.listen((event) {
      print("listening users in tags_matching_controller");
      if(event.isNotEmpty){
        allUsers = event.map((e) => e).toList();
        // myUser = allUsers.firstWhere((element) => element.id==FirebaseAuth.instance.currentUser!.uid);
        getMyTags();
      }
    });

  }

  Future getMyUser() async{

   DocumentSnapshot<Map<String,dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).get();
   myUser = getUserFromMap(documentSnapshot.data()!,documentSnapshot.id);
  }

  void getMyTags() {

    Map<String,dynamic> metadata = myUser!.metadata ?? {};
    myTags = ((metadata['tags'] ?? []) as List).map((e) => e.toString()).toList();

  }

  ///assuming myTags List is filled already
  Future<void> getAllTagsAndProcess() async{

    if(myTags.isEmpty){
      print("empty my tags, returning");
      return;
    }

    Map<String,dynamic> metadata = myUser!.metadata ?? {};

    List<String> analyzedTags = ((metadata['analyzedTags'] ?? []) as List).map((e) => e.toString()).toList();
    print("myTags $myTags");

    print("analyzedTags $analyzedTags");

    List<String> nonAnalyzedTags = myTags.map((e) => e.toString()).toList();
    nonAnalyzedTags.removeWhere((element) => analyzedTags.contains(element));

    print("nonAnalyzedTags $nonAnalyzedTags");


    if(nonAnalyzedTags.isEmpty){
      print("empty nonAnalyzed Tags returning");

      return;
    }

    List<types.User> skipUsers = [];
    List<String> skipTags = [];

    for (var user in allUsers) {

      if(skipUsers.any((element) => element.id==user.id)){
        continue;
      }

      Map<String,dynamic> metadata = user.metadata ?? {};
      List<String> userTags = ((metadata['tags'] ?? []) as List).map((e) => e.toString()).toList();

      if(userTags.isEmpty){
        continue;
      }


      for (var element in userTags) {
        if(skipTags.contains(element)){
          continue;
        }
        String? matchedTag = getTagIfExists(nonAnalyzedTags,element);

        ///common tag exists
        if(matchedTag!=null){

          Map<String,dynamic>? circleMap = await tagCircleExists(matchedTag);

          ///circle already exists for that tag
          if(circleMap!=null){
            await insertUser(circleMap);

            Map<String,dynamic> metadata = myUser!.metadata ?? {};
            List registrationIds = metadata['fcmTokens'] ?? [];

            await DBOperations.sendNotification(registrationIds: registrationIds, text: "We have added you to $matchedTag circle because of your favourite tag selection", title: "$matchedTag Circle");
            skipTags.add(matchedTag);

          }
          else{
            skipUsers = getCommonTagUsers(matchedTag).map((e) => e).toList();
            await createRoom(skipUsers, matchedTag);
            await markTagAsAnalyzedForOtherUsers(matchedTag, skipUsers);
          }

          await markTagAsAnalyzedForMyUser(matchedTag);

        }
      }
    }



    return ;

  }

  ///remove if tag is analyzed
  ///function not used yet
  Future removeAnalyzedTag(String tag, types.User user) async{
    Map<String,dynamic> metadata = user.metadata ?? {};

    List<String> analyzedTags = ((metadata['analyzedTags'] ?? []) as List).map((e) => e.toString()).toList();
    analyzedTags.removeWhere((element) => element==tag);
    metadata['analyzedTags'] = analyzedTags;

    await FirebaseFirestore.instance.collection('users').doc(myUser!.id).update(
        {
          'metadata' : metadata
        }
    );
    print("remove analyzed tag function completed");
  }

  String? getTagIfExists(List<String> tags, String element){

    try{
      return tags.firstWhere((tag) => tag==element);
    }

    catch(e){
      return null;

    }

  }

  // Future<void> handleTagsMatching(types.User myUser, types.User otherUser, String tag) async{
  //   Map<String,dynamic>? circleMap = await tagCircleExists(tag);
  //   if(circleMap!=null){
  //
  //   }
  // }

  Future<void> insertUser(Map<String,dynamic> circleMap) async{

    List<String> uIds = ((circleMap['userIds'] ?? []) as List).map((e) => e.toString()).toList();

    if(uIds.contains(FirebaseAuth.instance.currentUser!.uid)){

      print("circle ${circleMap['name']} already contains current user, so returning");

      return;
    }

    await FirebaseFirestore.instance.collection('rooms').doc(circleMap['id']).update(
        {
          'userIds' : FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
        }
    );
  }

  Future<void> createRoom(List<types.User> users, String tag)async{

    print("users recieved : ${users.length}");

    await FirebaseChatCore.instance
        .createGroupRoom(
        name: "$tag circle",
        users: users,
        imageUrl:
        "https://thumbs.dreamstime.com/b/linear-group-icon-customer-service-outline-collection-thin-line-vector-isolated-white-background-138644548.jpg",

        ///TODO ADD CLOUD MESSAGING IDS of All Users of Rooms
        metadata: {
          "group": true,
          'status': 'permanent',
          'privacy': 'public',
          'managers': [
            FirebaseAuth.instance.currentUser!.uid
          ],
          'description' : "This is an auto generated circle for $tag tag users",
          'tag' : tag
        });

    Map myMetadata = myUser!.metadata ?? {};

    print("my user tokens length: ${(myMetadata['fcmTokens'] as List).length}");

    print("my user tokens ${myMetadata['fcmTokens']}");

    List registrationIds = [...myMetadata['fcmTokens']];

   for (var element in users) {
     Map metadata = element.metadata ?? {};
     registrationIds.addAll(metadata['fcmTokens'] ?? [] );
     print("after ${element.firstName} iteration, length : ${registrationIds.length} ");

   }

   print("total fcmTokens length: ${registrationIds.length}");

   await DBOperations.sendNotification(registrationIds: registrationIds, text: "We have added you to $tag circle because of your favourite tag selection", title: "$tag Circle");
  }

  List<types.User> getCommonTagUsers(String tag){
    List<types.User> users = allUsers.map((e) => e).toList();
    users.removeWhere((user){
      Map<String,dynamic> metadata = user.metadata ?? {};
      List<String> tags =  ((metadata['tags'] ?? []) as List).map((e) => e.toString()).toList();
      return !(tags.contains(tag));
    });

    return users;
  }

  Future markTagAsAnalyzedForMyUser(String tag) async{

    Map<String,dynamic> metadata = myUser!.metadata ?? {};

    List<String> analyzedTags = ((metadata['analyzedTags'] ?? []) as List).map((e) => e.toString()).toList();
    analyzedTags.add(tag);
    metadata['analyzedTags'] = analyzedTags;

    await FirebaseFirestore.instance.collection('users').doc(myUser!.id).update(
        {
          'metadata' : metadata
        }
    );
  }


  Future markTagAsAnalyzedForOtherUsers(String tag, List<types.User> otherUsersList) async{
    for (var element in otherUsersList) {
      await markTagAsAnalyzedForOtherUser(tag, element);
    }

  }



  Future markTagAsAnalyzedForOtherUser(String tag, types.User otherUser) async{

    Map<String,dynamic> metadata = otherUser.metadata ?? {};

    List<String> analyzedTags = ((metadata['analyzedTags'] ?? []) as List).map((e) => e.toString()).toList();
    analyzedTags.add(tag);
    metadata['analyzedTags'] = analyzedTags;

    await FirebaseFirestore.instance.collection('users').doc(otherUser.id).update(
        {
          'metadata' : metadata
        }
    );
  }


  ///check if circle for this tag exists already
  Future<Map<String,dynamic>?> tagCircleExists(String tag) async{
   QuerySnapshot<Map<String,dynamic>> querySnapshot = await FirebaseFirestore.instance.collection('circles').get();
   List<Map<String,dynamic>> circlesMaps = querySnapshot.docs.map((e) {


     Map<String,dynamic> map = e.data();
     map['id'] = e.id;

     return map;
   }).toList();

   for (var element in circlesMaps) {

     Map<String,dynamic> metadata = element['metadata'] ?? {};


     if (metadata['tag'] ==tag)  {
       return element;
     }
   }

   return null;

  }

  types.User getUserFromMap(Map<String,dynamic> json,String id) {
    return types.User(
      createdAt: (json['createdAt'] as Timestamp).seconds,
      firstName: json['firstName'] as String?,
      id: id,
      imageUrl: json['imageUrl'] as String?,
      lastName: json['lastName'] as String?,
      lastSeen: null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      role: types.Role.user,
      updatedAt: (json['updatedAt'] as Timestamp).seconds,
    );
  }

}