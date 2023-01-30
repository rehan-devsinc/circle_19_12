import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService{

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize() {
    // initializationSettings  for Android
     InitializationSettings initializationSettings =
    const InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher",),
      iOS: DarwinInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      ),

    );

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        print("onDidReceiveNotificationResponse in initializing settings");
        print("notification id: ${notificationResponse.id}");
        print("notification input: ${notificationResponse.input}");
      },


    );
  }

  static void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    print("into on did receive local notification");
    print("notification id: $id");
    print("notification title: $title");
    print("notification title: $body");


  }

  static void createanddisplaynotification(RemoteMessage message) async{
    print("into create and display");
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "circledevapp",
          "circledevappchannel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data['_id'],
      );
    } on Exception catch (e) {
      print(e);
    }
  }



}
