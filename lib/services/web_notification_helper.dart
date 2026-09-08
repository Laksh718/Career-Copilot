// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> requestWebNotificationPermission() async {
  try {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    }
  } catch (_) {}
  return false;
}

void showWebNotification(String title, String body) {
  try {
    if (html.Notification.supported && html.Notification.permission == 'granted') {
      html.Notification(title, body: body, icon: 'favicon.ico');
    }
  } catch (_) {}
}
