import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // Placeholder: Notification initialization disabled due to dependency resolution issues.
    debugPrint("NotificationService initialized (Stub)");
  }

  Future<void> scheduleHydrationReminders() async {
    // Placeholder
    debugPrint("Hydration reminders scheduled (Stub)");
  }

  Future<void> cancelAll() async {
    // Placeholder
  }
}
