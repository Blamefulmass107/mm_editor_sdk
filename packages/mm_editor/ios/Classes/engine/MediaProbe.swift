# packages/mm_editor/ios/Classes/engine/MediaProbe.swift

import AVFoundation

class MediaProbe {

    static func probe(uriString: String) -> [String: Any] {

        guard let url = URL(string: uriString) else {
            return [:]
        }

        let asset = AVAsset(url: url)

        let durationMs = CMTimeGetSeconds(asset.duration) * 1000

        var width: Int = 0
        var height: Int = 0

        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            width = Int(abs(size.width))
            height = Int(abs(size.height))
        }

        let hasAudio = asset.tracks(withMediaType: .audio).count > 0

        return [
            "duration_ms": Int(durationMs),
            "width": width,
            "height": height,
            "rotation": 0,
            "frame_rate": 30,
            "has_audio": hasAudio,
            "audio_sample_rate": 48000
        ]
    }
}
