// packages/mm_editor/lib/src/api/editor.dart

import '../bridge/method_channel_bridge.dart';

class MMEditorConfig {
  final List<int> allowedResolutions; // e.g. [720,1080,1440,2160]
  final String defaultPreset; // "auto" | "720p" | ...

  MMEditorConfig({
    required this.allowedResolutions,
    this.defaultPreset = 'auto',
  });

  Map<String, dynamic> toJson() => {
        'allowed_resolutions': allowedResolutions,
        'default_preset': defaultPreset,
      };
}

class MMExportConfig {
  final String preset;
  final int? maxBitrateKbps;

  MMExportConfig({
    required this.preset,
    this.maxBitrateKbps,
  });

  Map<String, dynamic> toJson() => {
        'preset': preset,
        'max_bitrate_kbps': maxBitrateKbps,
      };
}

class MMExportResult {
  final String uri;
  final int durationMs;

  MMExportResult({
    required this.uri,
    required this.durationMs,
  });

  factory MMExportResult.fromJson(Map<String, dynamic> json) {
    return MMExportResult(
      uri: json['uri'],
      durationMs: json['duration_ms'],
    );
  }
}

class MMEditor {
  static Future<MMExportResult> export({
    required Map<String, dynamic> projectJson,
    required MMExportConfig export,
  }) async {
    final result = await MMEditorBridge.invoke('exportProject', {
      'project': projectJson,
      'export': export.toJson(),
    });

    final output = Map<String, dynamic>.from(result['output']);
    return MMExportResult.fromJson(output);
  }

  static Future<Map<String, dynamic>> probeMedia(String uri) async {
    final result = await MMEditorBridge.invoke('probeMedia', {
      'uri': uri,
    });

    return Map<String, dynamic>.from(result['media']);
  }
}
