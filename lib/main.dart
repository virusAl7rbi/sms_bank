// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

void messageHandler(SmsMessage message) {
  if (message.body.toString().contains("شراء")) {
  LineSplitter ls = const LineSplitter();
  List lines = ls.convert(message.body.toString());
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


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // set variable
  final Telephony telephony = Telephony.instance;
  // check permissions
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await Permission.ignoreBatteryOptimizations.isDenied.then((value) {
    if (value) {
      Permission.ignoreBatteryOptimizations.request();
    }
  });
  await Permission.sms.isDenied.then((value) {
    if (value) {
      Permission.sms.request();
    }
  });
  await telephony.requestPhoneAndSmsPermissions;
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
  // set sms listener
  telephony.listenIncomingSms(
      onNewMessage: messageHandler,
      onBackgroundMessage: messageHandler);
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
