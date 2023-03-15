import 'dart:convert';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void messageHandler(ServiceNotificationEvent message) async {
  List paymentWord = ['شراء', 'purchase'];
  List amountWord = ['مبلغ', 'amount'];
  String msg = message.content.toString().toLowerCase();
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
  bool? hasPermission = await NotificationListenerService.isPermissionGranted();
  if (!hasPermission) {
    NotificationListenerService.requestPermission();
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

Future<void> startListen() async {
  NotificationListenerService.notificationsStream
      .listen((event) => messageHandler(event));
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
      appRunner: () => runApp(const MyApp()),
    );
  } else {
    runApp(const MyApp());
  }
  // set listener
  await startListen();
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
