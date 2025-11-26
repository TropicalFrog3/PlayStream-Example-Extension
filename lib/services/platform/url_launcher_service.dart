import 'package:flutter/services.dart';

class UrlLauncherService {
  static const MethodChannel _channel = MethodChannel('com.playstream/url_launcher');
  
  static Future<bool> launchUrl(String url) async {
    try {
      final result = await _channel.invokeMethod('launchUrl', {'url': url});
      return result == true;
    } catch (e) {
      print('Error launching URL: $e');
      return false;
    }
  }
}
