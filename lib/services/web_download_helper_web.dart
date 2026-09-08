// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Triggers direct browser download of Career-Copilot.apk
void downloadApkFile() {
  html.AnchorElement(href: 'Career-Copilot.apk')
    ..setAttribute('download', 'Career-Copilot.apk')
    ..click();
}
