import 'package:get/get.dart';

class NewsFeedController extends GetxController{

  List<Rx<int>> currentIndexList = [];


  void fillList(int postsLength){
    currentIndexList.clear();

    for(int i=0; i<postsLength; i++){
      currentIndexList.add(0.obs);
    }

  }

  void modifyIndex(int index, {required int listItemIndex}){
    if(index<5){
      currentIndexList[listItemIndex].value = index;
    }
  }


}
