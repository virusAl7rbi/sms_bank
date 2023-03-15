
// ignore_for_file: prefer_const_constructors

import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

void messageHandler(NotificationEvent message) async {
  List paymentWord = ['شراء', 'purchase'];
  List amountWord = ['مبلغ', 'amount'];
  String msg = message.text.toString().toLowerCase();
  bool validate = paymentWord.any((item) => msg.contains(item));
  if (validate) {
    LineSplitter ls = const LineSplitter();
    List lines = ls.convert(msg);
    for (final i in lines) {
      if (amountWord.any((item) => i.contains(item))) {
        String price = i.toString().split(":")[1];
        //show notification
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: 123,
                channelKey: 'payment_amount',
                title: 'payment amount',
                body: price,
                category: NotificationCategory.Message));
      }
    }
  }
}

void checkNotificationPermissions() async {
  bool? hasPermission = await NotificationsListener.hasPermission;
  if (!hasPermission!) {
    NotificationsListener.openPermissionSettings();
    await AwesomeNotifications().requestPermissionToSendNotifications();
    return;
  }
}

disableBatteryOptimization() async {
  bool? isBatteryOptimizationDisabled =
      await DisableBatteryOptimization.isBatteryOptimizationDisabled;

  if (!isBatteryOptimizationDisabled!) {
    await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
  }
}

Future<void> initPlatformState() async {
  ReceivePort port = ReceivePort();
  NotificationsListener.initialize(callbackHandle: _callback);

  // this can fix restart<debug> can't handle error
  IsolateNameServer.removePortNameMapping("_listener_");
  IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");
  port.listen((message) => messageHandler(message));

  // don't use the default receivePort
  NotificationsListener.receivePort!.listen((evt) => messageHandler(evt));

}

void startListening() async {

  var hasPermission = await NotificationsListener.hasPermission;
  if (!hasPermission!) {
    NotificationsListener.openPermissionSettings();
    return;
  }

  var isR = await NotificationsListener.isRunning;

  if (!isR!) {
    await NotificationsListener.startService(
        foreground: false,
        title: "Listener Running",
        description: "Welcome to having me");
  }
}

void _callback(NotificationEvent evt) {
  final SendPort? send = IsolateNameServer.lookupPortByName("_listener_");
  send?.send(evt);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  checkNotificationPermissions();
  // disable battery optimization to keep app running
  await disableBatteryOptimization();
  // init notification
  AwesomeNotifications().initialize("resource://drawable/payment", [
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
  AwesomeNotifications().initialize("resource://drawable/payment", [
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

  if (!kDebugMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://575b700d4c364b49aad36daf0fe6f6c6@o4504306813960192.ingest.sentry.io/4504837853741056';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(MyApp()),
    );
  } else {
    runApp(MyApp());
  }
  // set listener
  initPlatformState();
  startListening();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: const Color.fromRGBO(128, 180, 251, 1),
            title: const Text("Payment amount"),
          ),
          body: const Center(
            child: Text(
              "This app will show notification on any payment sms with the amount,\n\n\t no need to open the app to receive the notification",
              style: TextStyle(fontSize: 25),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
