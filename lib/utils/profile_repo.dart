import 'package:circle/userinfo.dart';
import 'package:circle/utils/db_operations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';


class ProfileRepo{

  static Future<bool> addFriend(types.User otherUser) async{
    try{
      Map currentUserMap = await CurrentUserInfo.getCurrentUserMapFresh();
      Map currUserMD = currentUserMap['metadata'] ?? {};

      List currentUserFriends = currUserMD['friends'] ?? [];

      currentUserFriends.add(otherUser.id);
      currUserMD['friends'] = currentUserFriends;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"metadata": currUserMD});

      Map otherUserMD = otherUser.metadata ?? {};
      List otherUserFriends = otherUserMD['friends'] ?? [];
      otherUserFriends.add(FirebaseAuth.instance.currentUser!.uid);
      otherUserMD['friends'] = otherUserFriends;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUser.id)
          .update({"metadata": otherUserMD});

      Get.snackbar("Success","${otherUser.firstName} is now a friend",backgroundColor: Colors.white);

      return true;
    }
    catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<bool> removeFriend(types.User otherUser) async{
    try{
      Map currentUserMap = await CurrentUserInfo.getCurrentUserMapFresh();
      Map currUserMD = currentUserMap['metadata'] ?? {};

      List currentUserFriends = currUserMD['friends'] ?? [];

      currentUserFriends.remove(otherUser.id);
      currUserMD['friends'] = currentUserFriends;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"metadata": currUserMD});

      Map otherUserMD = otherUser.metadata ?? {};
      List otherUserFriends = otherUserMD['friends'] ?? [];
      otherUserFriends.remove(FirebaseAuth.instance.currentUser!.uid);
      otherUserMD['friends'] = otherUserFriends;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUser.id)
          .update({"metadata": otherUserMD});

      Get.snackbar("Success","${otherUser.firstName} is removed from friend-list", backgroundColor: Colors.white);

      return true;
    }
    catch(e){
      print(e.toString());
      return false;
    }
  }


  static bool isFriend(types.User otherUser){
    Map otherUserMD = otherUser.metadata ?? {};
    List otherUserFriends = otherUserMD['friends'] ?? [];

    return otherUserFriends.contains(FirebaseAuth.instance.currentUser!.uid);
  }

}