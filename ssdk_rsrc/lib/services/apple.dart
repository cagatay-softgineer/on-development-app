import 'package:flutter/services.dart';

class MusicKitPlatform {
  static const _channel = MethodChannel('com.ssdk_rsrc.musickit');

  static Future<void> playSong(String songId) async {
    await _channel.invokeMethod('playSong', {"songId": songId});
  }
}
