import 'package:get/get.dart';

class ViewPostController extends GetxController{

  Rx<int> currentIndex = 0.obs;



  void modifyIndex(int index){
    if(index<5){
      currentIndex.value = index;
    }
  }


}
