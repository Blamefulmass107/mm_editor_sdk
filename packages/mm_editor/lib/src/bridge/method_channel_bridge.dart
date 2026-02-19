// packages/mm_editor/lib/src/bridge/method_channel_bridge.dart

import 'dart:async';
import 'package:flutter/services.dart';
import '../api/errors.dart';

class MMEditorBridge {
  static const MethodChannel _channel = MethodChannel('mm_editor');
  static const EventChannel _eventChannel = EventChannel('mm_editor/events');

  static Stream<Map<String, dynamic>> get events =>
      _eventChannel.receiveBroadcastStream().map((event) {
        return Map<String, dynamic>.from(event);
      });

  static Future<Map<String, dynamic>> invoke(
      String method, Map<String, dynamic> args) async {
    try {
      final result = await _channel.invokeMethod(method, args);
      final map = Map<String, dynamic>.from(result);

      if (map['ok'] == true) return map;

      final error = Map<String, dynamic>.from(map['error'] ?? {});
      throw MMEditorException(
        code: error['code'] ?? MMEditorErrorCodes.internalError,
        message: error['message'] ?? 'Unknown error',
        details: error['details'] != null
            ? Map<String, dynamic>.from(error['details'])
            : null,
      );
    } on PlatformException catch (e) {
      throw MMEditorException(
        code: e.code,
        message: e.message ?? 'Platform error',
      );
    }
  }
}
