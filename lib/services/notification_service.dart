import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> budgetWarning(double spent, double budget) async {
    if (budget <= 0 || spent / budget < .8) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts', 'Alertas de presupuesto',
        channelDescription: 'Avisos al acercarte al límite de gasto',
        importance: Importance.high, priority: Priority.high,
      ),
    );
    await _plugin.show(1, 'Presupuesto semanal',
      'Has utilizado ${(spent / budget * 100).toStringAsFixed(0)}% de tu presupuesto.',
      details);
  }
}
