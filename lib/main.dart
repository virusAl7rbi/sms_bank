import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter/material.dart';

void messageHandler(NotificationEvent message) {
  if (message.text.toString().contains("شراء")) {
    LineSplitter ls = const LineSplitter();
    List lines = ls.convert(message.text.toString());
    String price = lines[3].toString().split(":")[1];

    //show notification
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 123,
            channelKey: 'payment_amount',
            title: 'payment amount',
            body: price,
            category: NotificationCategory.Message));
  }
}

void startListening() async {
  bool? hasPermission = await NotificationsListener.hasPermission;
  if (!hasPermission!) {
    NotificationsListener.openPermissionSettings();
    return;
  }

  var isR = await NotificationsListener.isRunning;

  if (!isR!) {
    await NotificationsListener.startService();
  }
}

Future<void> initPlatformState() async {
  NotificationsListener.initialize(callbackHandle: messageHandler);
  // register you event handler in the ui logic.
  NotificationsListener.receivePort!.listen((evt) => messageHandler(evt));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init notification
  AwesomeNotifications().initialize('resource://drawable/payment', [
    NotificationChannel(
      channelGroupKey: 'payment_amount',
      channelKey: 'payment_amount',
      channelName: 'payment amount notification',
      channelDescription: 'payment amount notification',
      channelShowBadge: true,
      importance: NotificationImportance.Max,
      enableVibration: true,
    ),
  ]);
  AwesomeNotifications().initialize('resource://drawable/payment', [
    NotificationChannel(
        channelGroupKey: 'payment_amount',
        channelKey: 'payment_amount_keep_background',
        channelName: 'payment amount notification for background',
        channelDescription: 'payment amount notification',
        channelShowBadge: false,
        importance: NotificationImportance.Max,
        enableVibration: false,
        playSound: false,
        criticalAlerts: false),
  ]);
  // show notification to keep app on background
  AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1234,
          channelKey: 'payment_amount_keep_background',
          title: 'payment amount',
          body: "this notification is show to keep the app running",
          locked: true,
          autoDismissible: false,
          actionType: ActionType.SilentAction,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Service));

  runApp(const MyApp());
  // set listener
  await initPlatformState();
  startListening();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "This app will show notification on any payment sms with the amount,\n\n\t no need to open the app to receive the notification",
            style: TextStyle(fontSize: 25),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
