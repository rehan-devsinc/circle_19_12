import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class GroupInfoController extends GetxController{
  Rx<bool> loading = false.obs;

  Rx<bool> locationLoading = false.obs;

  XFile? pickedFile = null;

}