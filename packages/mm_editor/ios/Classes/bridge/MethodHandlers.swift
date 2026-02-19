# packages/mm_editor/ios/Classes/bridge/MethodHandlers.swift

import Flutter
import UIKit

class MethodHandlers {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {

        case "probeMedia":
            guard let args = call.arguments as? [String: Any],
                let uri = args["uri"] as? String else {
                result(error(code: "INVALID_ARGUMENT", message: "Missing uri"))
                return
            }

            let media = MediaProbe.probe(uriString: uri)
            result(success(["media": media]))

        case "exportProject":
            // TODO: Implement AVAssetExportSession pipeline
            result(success([
                "output": [
                    "uri": "file:///tmp/mm_export.mp4",
                    "duration_ms": 0
                ]
            ]))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func success(_ payload: [String: Any]) -> [String: Any] {
        var base: [String: Any] = ["ok": true]
        payload.forEach { base[$0.key] = $0.value }
        return base
    }

    private func error(code: String, message: String) -> [String: Any] {
        return [
            "ok": false,
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }
}
