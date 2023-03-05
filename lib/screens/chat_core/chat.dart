import 'dart:io';

import 'package:circle/models/post_model.dart';
import 'package:circle/screens/chat_core/group_info.dart';
import 'package:circle/screens/other_user_profile.dart';
import 'package:circle/screens/posts/add_post_screen.dart';
import 'package:circle/screens/posts/view_post_screen.dart';
import 'package:circle/userinfo.dart';
import 'package:circle/utils/db_operations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../circle_members.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.room,
    this.groupChat = false,
    // required this.otherUser,
  });

  final bool groupChat;

  final types.Room room;
  // final types.User otherUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isAttachmentUploading = false;

  // String title = "";
  types.User? otherUser;

  @override
  void initState() {
    // for(int i=0; i<widget.room.users.length; i++){
    //   if(widget.room.users[i].id != FirebaseAuth.instance.currentUser!.uid){
    //     title = title + (widget.room.users[i].firstName ?? "user $i") + " ";
    //   }
    // }

    print(widget.room);
    print("last messages: ${widget.room.lastMessages}");

    if (!(widget.room.type==(types.RoomType.group))) {
      for (int i = 0; i < widget.room.users.length; i++) {
        if (widget.room.users[i].id != FirebaseAuth.instance.currentUser!.uid) {
          otherUser = widget.room.users[i];
          break;
        }
      }
    }

    // FirebaseChatCore.instance.createGroupRoom(name: name, users: users);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: (!(widget.room.type==(types.RoomType.group)))
            ? InkWell(
          onTap: (){
            Get.to(()=>OtherUserProfileScreen(otherUser: otherUser!));
          },
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          otherUser!.imageUrl ??
                              "https://media.istockphoto.com/vectors/user-avatar-profile-icon-black-vector-illustration-vector-id1209654046?k=20&m=1209654046&s=612x612&w=0&h=Atw7VdjWG8KgyST8AXXJdmBkzn0lvgqyWod9vTb2XoE=",
                          width: 40,
                          height: 40,
                        )),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(otherUser!.firstName!, style: TextStyle(color: Colors.black),)
                    // Text(title),
                  ],
                ),
            )
            :

            ///GROUP APP BAR
            InkWell(
                onTap: (){
                  if(widget.room.type == (types.RoomType.group)) {
                    Get.to(CircleMembersScreen(
                      groupRoom: widget.room,
                    ));
                  }
                },
                child:
                    ///new group app bar for showing members
                Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.room.users.length > 2 ? 3 : widget.room.users.length ,
                          itemBuilder: (context,index){
                          return userImageAvatar(widget.room.users[index].imageUrl!);
                          }),
                    ),
                    const SizedBox(height: 3,),
                    const Text("View all members ->", style: TextStyle(fontSize: 12, color: Colors.black),)
                  ],
                )

            ),
        leading: InkWell(
            onTap: (){
              Get.back();
            },
            child: const Icon(Icons.arrow_back,color: Colors.black,)),
        centerTitle: true,
        actions: [
          (widget.room.type == (types.RoomType.group))
              ? Row(
            mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                      onTap: () {
                        Get.to(GroupInfoScreen(groupRoom: widget.room));
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.info_outline, color: Colors.purple,),
                      ),
                    ),
                  InkWell(
                      onTap: (){
                        Get.to(()=>AddPostScreen(groupRoom: widget.room,goToPostsPage: true,));
                      },
                      child: const Icon(Icons.add_circle, color: Colors.green,)),
                  10.horizontalSpace,
                ],
              )
              : MuteTextButton(room: widget.room)
          // PopupMenuButton<String>(
          //   icon: Icon(CupertinoIcons.ellipsis_vertical),
          //   // icon: Icon(Icons.add_circle_outline_outlined, size: 36, color: Colors.white.withOpacity(0.8),),
          //   // color: Color.fromRGBO(87, 87, 87, 0.5), // background color
          //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          //     PopupMenuItem<String>(
          //       value: "Group Info",
          //       onTap: () {
          //         print("hi");
          //         Get.to(()=> GroupInfoScreen(groupRoom: widget.room));
          //         // Navigator.pushReplacement(buildContext, MaterialPageRoute(builder: (context) {
          //         //   print("Hi there");
          //         //   return GroupInfoScreen(
          //         //     groupRoom: widget.room,
          //         //   );
          //         // }));
          //       },
          //       child: const Text(
          //         'Group Info',
          //         // style: TextStyle(color: Colors.red),
          //       ),
          //     ),
          //   ],
          // )
        ],
      ),
      body: StreamBuilder<types.Room>(
        initialData: widget.room,
        stream: FirebaseChatCore.instance.room(widget.room.id),
        builder: (context, snapshot) => StreamBuilder<List<types.Message>>(
          initialData: const [],
          stream: FirebaseChatCore.instance.messages(snapshot.data!),
          builder: (context, snapshot)
          {

            List<types.Message> messages = snapshot.data?.map((types.Message e) => e).toList() ?? [];

            print("before removing:");
            print(            messages.any((element) {
              if (element.type==(types.MessageType.text)){
                types.TextMessage textMessage = types.TextMessage.fromJson(element.toJson());
                return textMessage.text.trim().isEmpty;
              }
              return false;
            } ));

            messages.removeWhere((element) {
              if (element.type==(types.MessageType.text)){
                types.TextMessage textMessage = types.TextMessage.fromJson(element.toJson());
                return textMessage.text.trim().isEmpty;
              }
              return false;
            } );


            print("after removing:");
            print(messages.any((element) {
              if (element.type==(types.MessageType.text)){
                types.TextMessage textMessage = types.TextMessage.fromJson(element.toJson());
                return textMessage.text.trim().isEmpty;
              }
              return false;
            } ));



            return Chat(
              textMessageOptions: TextMessageOptions(
                isTextSelectable: false,

                onLinkPressed:true? null : (String link)async{
                  try {
                  if (!await launchUrl(Uri.parse(link),mode: LaunchMode.externalApplication)) {
                    throw throw Exception('Could not launch $link');
                  }
                }
                catch(e){
                    if (kDebugMode) {
                      print(e.toString());
                    }
                }
              }
              ),
              onMessageDoubleTap: _handleMessageTap,
              theme: const DefaultChatTheme(primaryColor: Colors.black87),
              showUserAvatars: true,
              showUserNames: true,
              isAttachmentUploading: _isAttachmentUploading,
              messages: messages,
              onAttachmentPressed: _handleAtachmentPressed,
              onMessageTap: _handleMessageTap,
              onPreviewDataFetched: _handlePreviewDataFetched,
              onSendPressed: _handleSendPressed,
              user: types.User(
                id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
              ),
              customBottomWidget: _buildCustomBottomWidget(),
            );
          },
        ),
      ),
    );
  }


  // final Widget Function(types.ImageMessage, {required int messageWidth})?
  // imageMessageBuilder = _customImageMessageBuilder;



  final TextEditingController inputMessageController = TextEditingController();

 Widget  _buildCustomBottomWidget(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
      child: Row(
        children: [
          SizedBox(width: 20,),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextFormField(
                controller: inputMessageController,
                decoration: InputDecoration(
                  hintText: "Message",
                  suffixIcon: InkWell(
                    onTap: (){
                      _handleAtachmentPressed();
                    },
                      child: Icon(Icons.add_circle_outline, color: Colors.purple,)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20)
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 30,),
          InkWell(
              onTap: (){
                if(inputMessageController.text.trim().isNotEmpty){
                  _handleSendPressed(
                      types.PartialText(text: inputMessageController.text));
                  inputMessageController.clear();
                }
              },
              child: const Icon(Icons.send,size: 35,))
        ],
      ),
    );

  }

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photo (Gallery)'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection(camera: true);
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photo (Camera)'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection(video: true);
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Video (Camera)'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);

        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.room.id)
            .update({"lastMsg": "file"});
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection({bool camera = false, bool video = false}) async {
    final result = (!video)
        ? (await ImagePicker().pickImage(
            imageQuality: 70,
            maxWidth: 1440,
            source: camera ? ImageSource.camera : ImageSource.gallery,
          ))
        : (await ImagePicker().pickVideo(
            maxDuration: Duration(seconds: 30), source: ImageSource.camera));

    if (result != null && video == true) {
      _setAttachmentUploading(true);
      final name = result.name;
      final filePath = result.path;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: file.statSync().size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);

        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.room.id)
            .update({"lastMsg": "file"});
      } finally {
        _setAttachmentUploading(false);
      }
      return;
    }

    if (result != null) {
      _setAttachmentUploading(true);
      final file = File(result.path);
      final size = file.lengthSync();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final name = result.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(
          message,
          widget.room.id,
        );
        _setAttachmentUploading(false);
        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.room.id)
            .update({"lastMsg": "photo"});
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
   print("into handle message tap");
//   if (message is types.Cu)
    if (message is types.FileMessage) {
      print("message type is file message");

      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final updatedMessage = message.copyWith(isLoading: true);
          FirebaseChatCore.instance.updateMessage(
            updatedMessage,
            widget.room.id,
          );

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final updatedMessage = message.copyWith(isLoading: false);
          FirebaseChatCore.instance.updateMessage(
            updatedMessage,
            widget.room.id,
          );
        }
      }


      await OpenFilex.open(localPath);
    }
    else if ((message.metadata ?? {})['post'] != null){
      PostModel postModel = PostModel.fromJson(message.metadata!['post']);
      Get.to(()=>ViewPostScreen(postModel: postModel));
    }
    else{
      print("message type is not file message, returning");
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  void _handleSendPressed(types.PartialText message) async {
    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
    );

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.room.id)
        .update({"lastMsg": message.text});
    List registrationIds = [];

    types.Room newRoom =
        await FirebaseChatCore.instance.room(widget.room.id).first;

    Map metadata = newRoom.metadata ?? {};
    List mutedBy = metadata['mutedBy'] ?? [];
    for (var element in mutedBy) {
      element = element.toString();
    }

    print("muted by $mutedBy");

    for (var user in newRoom.users) {
      if (mutedBy.contains(user.id)) {
        continue;
      }

      Map map = user.metadata ?? {};
      List fcmTokens = map['fcmTokens'] ?? [];
      registrationIds.addAll(fcmTokens);
    }

    String myToken = await DBOperations.getDeviceTokenToSendNotification();

    registrationIds.removeWhere((element) => element.toString() == myToken);

    Map userMap = await CurrentUserInfo.getCurrentUserMap();

    print("registration ids: $registrationIds");

    await DBOperations.sendNotification(
      registrationIds: registrationIds,
      title: "${userMap['firstName']} ${userMap['lastName']}",
      text: message.text,
    );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

}

class MuteTextButton extends StatefulWidget {
  final types.Room room;

  const MuteTextButton({Key? key, required this.room}) : super(key: key);

  @override
  State<MuteTextButton> createState() => _MuteTextButtonState();
}

class _MuteTextButtonState extends State<MuteTextButton> {
  bool muted = false;
  List mutedIds = [];
  Map metadata = {};
  bool loading = false;

  @override
  void initState() {
    metadata = widget.room.metadata ?? {};
    mutedIds = metadata['mutedBy'] ?? [];
    for (var element in mutedIds) {
      element = element.toString();
    }

    ///If already muted
    if (mutedIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
      muted = true;
    }

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? SizedBox(
            height: 20,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white,),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: TextButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });

                  if (muted) {
                    mutedIds.removeWhere((element) =>
                        element == FirebaseAuth.instance.currentUser!.uid);
                    muted = false;
                  } else {
                    mutedIds.add(FirebaseAuth.instance.currentUser!.uid);
                    muted = true;
                  }

                  metadata['mutedBy'] = mutedIds;
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.room.id)
                      .update({'metadata': metadata});
                  setState(() {
                    loading = false;
                  });

                  if (muted) {
                    Get.snackbar("Success", "Circle Muted",
                        backgroundColor: Colors.white);
                  } else {
                    Get.snackbar("Success", "Circle Unmuted",
                        backgroundColor: Colors.white);
                  }
                },
                child: Text(
                  muted ? "Unmute" : "Mute",
                  style: TextStyle(
                      color: !muted? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )),
          );
  }
}

Widget userImageAvatar(String url){
  return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.network(
        url,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
      ));
}

