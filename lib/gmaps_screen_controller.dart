import 'package:get/get.dart';

class GoogleMapsScreenController extends GetxController{

  late Rx<int> selectedIndex;


  GoogleMapsScreenController({bool firstUserSelected = false}){
    if(firstUserSelected){
      selectedIndex = (0).obs;
    }
    else{
      selectedIndex = (-1).obs;
    }
  }

}