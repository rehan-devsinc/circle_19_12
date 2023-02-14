import 'package:circle/controllers/news_feed_controller.dart';
import 'package:circle/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'news_feed_screen.dart';

class ViewPostScreen extends StatefulWidget {
  const ViewPostScreen({Key? key, required this.postModel}) : super(key: key);
  final PostModel postModel;

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  final NewsFeedController newsFeedController = NewsFeedController();

  @override
  void initState() {
    newsFeedController.fillList(1);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Post "),),
      body: Padding(
        padding:  EdgeInsets.only(top: 25.h),
        child: Column(
          children: [
            FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.postModel.authorId)
                    .get(),
                builder: (context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    snapshot) {
                  if (!(snapshot.hasData) ||
                      snapshot.connectionState ==
                          ConnectionState.waiting) {
                    return  SizedBox(
                      height: widget.postModel.picturesList.isNotEmpty ? 0.6.sh : 0.1.sh,
                    );
                  }

                  return buildPostWidget(
                      snapshot.data!.data()!, widget.postModel,listItemIndex: 0,userId: widget.postModel.authorId,newsFeedController: newsFeedController );
                }),
            Divider(),
          ],
        ),
      )
    );
  }
}
