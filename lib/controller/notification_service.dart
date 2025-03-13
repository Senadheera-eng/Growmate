// notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:uuid/uuid.dart';
import '../model/tree_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  // Factory constructor to return the same instance
  factory NotificationService() {
    return _instance;
  }

  // Private constructor for singleton pattern
  NotificationService._internal();

  /* Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print("Firebase messaging permission status: ${settings.authorizationStatus}");


    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Request exact alarms permission for Android 12+
    if (Platform.isAndroid) {
      AndroidFlutterLocalNotificationsPlugin androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!;

      // Request exact alarms permission
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Handle FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);

    // Get the token if it's available
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    _initialized = true;
  } */
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    print("Starting notification service initialization");

    // Create notification channel for Android
    if (Platform.isAndroid) {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        'tree_reminders_channel',
        'Tree Care Reminders',
        description: 'Notifications for tree care reminders',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print("Android notification channel created");
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification tapped with payload: ${response.payload}");
        _handleNotificationTap(response.payload);
      },
    );

    // Request exact alarms permission for Android 12+
    if (Platform.isAndroid) {
      AndroidFlutterLocalNotificationsPlugin androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!;

      // Request exact alarms permission
      await androidImplementation.requestExactAlarmsPermission();

      // Check notification permission (Android 13+)
      final bool? granted =
          await androidImplementation.areNotificationsEnabled();
      print("Android notifications enabled: $granted");

      if (granted != true) {
        print("Requesting notification permission");
        await _firebaseMessaging.requestPermission();
      }
    }

    // Request permission for notifications (Firebase)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print(
        "Firebase messaging permission status: ${settings.authorizationStatus}");

    // Handle FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);

    // Get the token if it's available
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
      print("Firebase messaging token obtained");
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");
      _handleForegroundMessage(message);
    });

    print("Notification service initialization complete");
    _initialized = true;
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(String? payload) async {
    if (payload != null) {
      // Parse the payload and navigate accordingly
      // This would typically be handled by your navigation service
      print('Notification tapped with payload: $payload');

      // You can parse the payload and navigate to the appropriate screen
      // For example, if payload contains a treeId, navigate to that tree's detail page
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tokens')
        .doc('fcm')
        .set({
      'token': token,
      'platform': _getPlatform(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get platform info
  String _getPlatform() {
    if (identical(0, 0.0)) {
      return 'web';
    }
    return 'mobile';
  }

  // Schedule watering reminder for a specific tree
  Future<void> scheduleWateringReminder(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check if watering reminders are enabled
    final prefs = await SharedPreferences.getInstance();
    final wateringRemindersEnabled =
        prefs.getBool('watering_reminders_enabled') ?? true;
    if (!wateringRemindersEnabled) return;

    // Determine appropriate watering interval based on tree age
    final wateringIntervalDays = _getWateringIntervalForTree(tree);

    // Find last watering date from care_tip_completions
    final lastWateringDoc = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .orderBy('completedDate', descending: true)
        .limit(1)
        .get();

    DateTime nextWateringDate;

    if (lastWateringDoc.docs.isNotEmpty) {
      // Calculate next watering based on last watering
      final lastWateringData = lastWateringDoc.docs.first.data();
      final lastWateringDate =
          DateTime.parse(lastWateringData['completedDate']);
      nextWateringDate =
          lastWateringDate.add(Duration(days: wateringIntervalDays));
    } else {
      // No watering records, schedule from today
      nextWateringDate = DateTime.now().add(Duration(days: 1));
    }

    // Only schedule if the date is in the future
    if (nextWateringDate.isAfter(DateTime.now())) {
      await _scheduleLocalNotification(
        id: _generateNotificationId(tree.id, 'watering'),
        title: 'Time to water ${tree.name}!',
        body: 'Your tree needs water to stay healthy',
        scheduledDate: nextWateringDate,
        payload: 'watering:${tree.id}',
      );

      // Also store in Firestore for syncing across devices
      await _storeScheduledNotification(
        type: 'watering',
        treeId: tree.id,
        scheduledDate: nextWateringDate,
        title: 'Time to water ${tree.name}!',
        body: 'Your tree needs water to stay healthy',
      );
    }
  }

  // Schedule treatment reminder for a diseased tree
  Future<void> scheduleTreatmentReminder(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || !tree.isDiseased || tree.diseaseId == null) return;

    // Check if treatment reminders are enabled
    final prefs = await SharedPreferences.getInstance();
    final treatmentRemindersEnabled =
        prefs.getBool('treatment_reminders_enabled') ?? true;
    if (!treatmentRemindersEnabled) return;

    // Get current in-progress treatment step
    final treatmentQuery = await _firestore
        .collection('treatment_progress')
        .where('treeId', isEqualTo: tree.id)
        .where('diseaseId', isEqualTo: tree.diseaseId)
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in treatmentQuery.docs) {
      final data = doc.data();

      // Skip completed steps
      if (data.containsKey('completedDate') && data['completedDate'] != null)
        continue;

      // Found an in-progress step
      final startedDate = DateTime.parse(data['startedDate']);
      final stepId = data['stepId'];

      // Get information about this step
      final stepDoc =
          await _firestore.collection('treatment_steps').doc(stepId).get();

      if (!stepDoc.exists) continue;

      final stepData = stepDoc.data()!;
      final recommendedDays = stepData['recommendedDays'] ?? 7;
      final stepNumber = stepData['stepNumber'];

      // Calculate recommended completion date
      final recommendedCompletionDate =
          startedDate.add(Duration(days: recommendedDays));

      // Schedule reminder for 80% of the way through the recommended period
      final reminderDate =
          startedDate.add(Duration(days: (recommendedDays * 0.8).round()));

      // Only schedule if the date is in the future
      if (reminderDate.isAfter(DateTime.now())) {
        await _scheduleLocalNotification(
          id: _generateNotificationId(tree.id, 'treatment_${stepDoc.id}'),
          title: 'Treatment Reminder for ${tree.name}',
          body: 'Time to check on Step $stepNumber of your treatment plan',
          scheduledDate: reminderDate,
          payload: 'treatment:${tree.id}:${tree.diseaseId}:${stepDoc.id}',
        );

        // Store in Firestore
        await _storeScheduledNotification(
          type: 'treatment',
          treeId: tree.id,
          scheduledDate: reminderDate,
          title: 'Treatment Reminder for ${tree.name}',
          body: 'Time to check on Step $stepNumber of your treatment plan',
          additionalData: {
            'diseaseId': tree.diseaseId,
            'stepId': stepDoc.id,
            'stepNumber': stepNumber,
          },
        );
      }

      // Also schedule a reminder on the recommended completion date
      if (recommendedCompletionDate.isAfter(DateTime.now())) {
        await _scheduleLocalNotification(
          id: _generateNotificationId(
              tree.id, 'treatment_completion_${stepDoc.id}'),
          title: 'Complete Treatment Step for ${tree.name}',
          body: 'Today is the recommended day to complete Step $stepNumber',
          scheduledDate: recommendedCompletionDate,
          payload:
              'treatment:${tree.id}:${tree.diseaseId}:${stepDoc.id}:complete',
        );

        // Store in Firestore
        await _storeScheduledNotification(
          type: 'treatment_completion',
          treeId: tree.id,
          scheduledDate: recommendedCompletionDate,
          title: 'Complete Treatment Step for ${tree.name}',
          body: 'Today is the recommended day to complete Step $stepNumber',
          additionalData: {
            'diseaseId': tree.diseaseId,
            'stepId': stepDoc.id,
            'stepNumber': stepNumber,
          },
        );
      }
    }
  }

  // Schedule regular care reminders
  Future<void> scheduleCareTipReminders(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check if care tip reminders are enabled
    final prefs = await SharedPreferences.getInstance();
    final careTipsRemindersEnabled =
        prefs.getBool('care_tips_reminders_enabled') ?? true;
    if (!careTipsRemindersEnabled) return;

    // Get care tips relevant to this tree's age
    final careTipsQuery = await _firestore
        .collection('care_tips')
        .where('minimumAge', isLessThanOrEqualTo: tree.ageInMonths)
        .where('maximumAge', isGreaterThanOrEqualTo: tree.ageInMonths)
        .get();

    // Get already completed tips
    final completedTipsQuery = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .get();

    final completedTipIds = completedTipsQuery.docs
        .map((doc) => doc.data()['tipId'] as String)
        .toSet();

    // Schedule reminders for tips that haven't been completed yet
    int tipCount = 0;
    for (var doc in careTipsQuery.docs) {
      if (completedTipIds.contains(doc.id)) continue;

      final tipData = doc.data();
      final tipCategory = tipData['category'];

      // Skip watering tips as they have their own schedule
      if (tipCategory == 'watering') continue;

      // Calculate scheduled date (stagger the tips over several days)
      final scheduledDate = DateTime.now().add(Duration(days: 2 + tipCount));

      await _scheduleLocalNotification(
        id: _generateNotificationId(tree.id, 'care_tip_${doc.id}'),
        title: 'Care Tip for ${tree.name}',
        body: tipData['title'],
        scheduledDate: scheduledDate,
        payload: 'care_tip:${tree.id}:${doc.id}',
      );

      // Store in Firestore
      await _storeScheduledNotification(
        type: 'care_tip',
        treeId: tree.id,
        scheduledDate: scheduledDate,
        title: 'Care Tip for ${tree.name}',
        body: tipData['title'],
        additionalData: {
          'tipId': doc.id,
          'category': tipCategory,
        },
      );

      tipCount++;

      // Limit to 3 care tips at a time to avoid overwhelming the user
      if (tipCount >= 3) break;
    }
  }

  // Schedule fertilization reminders
  Future<void> scheduleFertilizationReminder(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check if fertilization reminders are enabled
    final prefs = await SharedPreferences.getInstance();
    final fertilizationRemindersEnabled =
        prefs.getBool('fertilization_reminders_enabled') ?? true;
    if (!fertilizationRemindersEnabled) return;

    // Find last fertilization from care_tip_completions
    final lastFertilizationQuery = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .get();

    // Filter for fertilization tips
    final fertilizationDocs =
        await Future.wait(lastFertilizationQuery.docs.map((doc) async {
      final tipId = doc.data()['tipId'];
      final tipDoc = await _firestore.collection('care_tips').doc(tipId).get();

      if (tipDoc.exists && tipDoc.data()?['category'] == 'fertilization') {
        return doc;
      }
      return null;
    }));

    final filteredDocs = fertilizationDocs.where((doc) => doc != null).toList();
    filteredDocs.sort((a, b) => DateTime.parse(b!.data()['completedDate'])
        .compareTo(DateTime.parse(a!.data()['completedDate'])));

    DateTime nextFertilizationDate;

    if (filteredDocs.isNotEmpty) {
      // Calculate next fertilization date (typically every 4-8 weeks)
      final lastFertilizationDate =
          DateTime.parse(filteredDocs.first!.data()['completedDate']);
      final fertInterval = _getFertilizationIntervalForTree(tree);
      nextFertilizationDate =
          lastFertilizationDate.add(Duration(days: fertInterval));
    } else {
      // No fertilization records, schedule from now + 3 days
      nextFertilizationDate = DateTime.now().add(Duration(days: 3));
    }

    if (nextFertilizationDate.isAfter(DateTime.now())) {
      await _scheduleLocalNotification(
        id: _generateNotificationId(tree.id, 'fertilization'),
        title: '${tree.name} needs nutrients!',
        body: 'It\'s time to fertilize your tree for optimal growth',
        scheduledDate: nextFertilizationDate,
        payload: 'fertilization:${tree.id}',
      );

      // Store in Firestore
      await _storeScheduledNotification(
        type: 'fertilization',
        treeId: tree.id,
        scheduledDate: nextFertilizationDate,
        title: '${tree.name} needs nutrients!',
        body: 'It\'s time to fertilize your tree for optimal growth',
      );
    }
  }

  // Store scheduled notification in Firestore for syncing across devices
  Future<void> _storeScheduledNotification({
    required String type,
    required String treeId,
    required DateTime scheduledDate,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notificationId = const Uuid().v4();

    await _firestore
        .collection('scheduled_notifications')
        .doc(notificationId)
        .set({
      'userId': userId,
      'treeId': treeId,
      'type': type,
      'scheduledDate': scheduledDate.toIso8601String(),
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
      ...?additionalData,
    });
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tree_reminders_channel',
        'Tree Care Reminders',
        channelDescription: 'Notifications for tree care reminders',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'GrowMate Reminder',
        icon: 'ic_notification',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Convert to TZDateTime for timezone-aware scheduling
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      try {
        // Try to schedule an exact notification
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e) {
        if (e.toString().contains('exact_alarms_not_permitted')) {
          // Fall back to inexact scheduling if exact permission denied
          await _localNotifications.zonedSchedule(
            id,
            title,
            body,
            tzDateTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          print('Using inexact alarms as fallback');
        } else {
          rethrow; // For other errors, rethrow
        }
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Generate predictable notification ID
  int _generateNotificationId(String treeId, String type) {
    // Create a predictable but unique ID based on the treeId and type
    String combined = '$treeId:$type';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (hash * 31 + combined.codeUnitAt(i)) % 1000000;
    }
    return hash;
  }

  // Determine watering interval based on tree age and other factors
  int _getWateringIntervalForTree(TreeModel tree) {
    // Young trees need more frequent watering
    if (tree.ageInMonths < 6) {
      return 2; // Every 2 days
    } else if (tree.ageInMonths < 12) {
      return 3; // Every 3 days
    } else if (tree.ageInMonths < 24) {
      return 4; // Every 4 days
    } else {
      return 7; // Weekly for mature trees
    }
  }

  // Determine fertilization interval based on tree age
  int _getFertilizationIntervalForTree(TreeModel tree) {
    // Young trees need more frequent fertilization
    if (tree.ageInMonths < 6) {
      return 21; // Every 3 weeks
    } else if (tree.ageInMonths < 12) {
      return 30; // Monthly
    } else {
      return 45; // Every 6 weeks for mature trees
    }
  }

  // Cancel all reminders for a specific tree
  Future<void> cancelTreeReminders(String treeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Delete from Firestore
    final batch = _firestore.batch();
    final scheduledNotifications = await _firestore
        .collection('scheduled_notifications')
        .where('treeId', isEqualTo: treeId)
        .where('userId', isEqualTo: userId)
        .where('sent', isEqualTo: false)
        .get();

    for (var doc in scheduledNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Cancel local notifications
    // We can't easily identify specific notifications by treeId,
    // so we'll cancel them by their generated IDs when needed

    // Cancel watering reminders
    await _localNotifications
        .cancel(_generateNotificationId(treeId, 'watering'));

    // For other reminders, we would need to store the generated IDs somewhere
    // and cancel them individually
  }

  // Refresh all notifications for all trees
  Future<void> refreshAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get all user's trees
    final treesQuery = await _firestore
        .collection('trees')
        .where('userId', isEqualTo: userId)
        .get();

    // Cancel existing notifications
    await _localNotifications.cancelAll();

    // Delete scheduled notifications from Firestore
    final batch = _firestore.batch();
    final scheduledNotifications = await _firestore
        .collection('scheduled_notifications')
        .where('userId', isEqualTo: userId)
        .where('sent', isEqualTo: false)
        .get();

    for (var doc in scheduledNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Reschedule for each tree
    for (var doc in treesQuery.docs) {
      final tree = TreeModel.fromMap({...doc.data(), 'id': doc.id});

      await scheduleWateringReminder(tree);
      await scheduleFertilizationReminder(tree);
      await scheduleCareTipReminders(tree);

      if (tree.isDiseased) {
        await scheduleTreatmentReminder(tree);
      }
    }
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool wateringReminders,
    required bool fertilizationReminders,
    required bool careTipsReminders,
    required bool treatmentReminders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watering_reminders_enabled', wateringReminders);
    await prefs.setBool(
        'fertilization_reminders_enabled', fertilizationReminders);
    await prefs.setBool('care_tips_reminders_enabled', careTipsReminders);
    await prefs.setBool('treatment_reminders_enabled', treatmentReminders);

    // Refresh notifications based on new preferences
    await refreshAllNotifications();
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'watering': prefs.getBool('watering_reminders_enabled') ?? true,
      'fertilization': prefs.getBool('fertilization_reminders_enabled') ?? true,
      'care_tips': prefs.getBool('care_tips_reminders_enabled') ?? true,
      'treatment': prefs.getBool('treatment_reminders_enabled') ?? true,
    };
  }

  // Handler for foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tree_reminders_channel',
            'Tree Care Reminders',
            channelDescription: 'Notifications for tree care reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: message.data['payload'],
      );
    }
  }

  //Public method for testing
  // Add this to notification_service.dart
  Future<void> scheduleTestNotification() async {
    print("Attempting to show test notification");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'tree_reminders_channel', // Important: use the same channel ID
      'Tree Care Reminders',
      channelDescription: 'Notifications for tree care reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'GrowMate Test',
      icon: 'ic_notification',  
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show immediate notification instead of scheduling
    await _localNotifications.show(
      9999,
      'Test Notification',
      'This is a test notification from GrowMate',
      notificationDetails,
    );

    print("Test notification requested");
  }
}

// Background message handler needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // For background messages, you typically don't need to do anything
  // as the system will automatically show a notification
}
