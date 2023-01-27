import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;


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
