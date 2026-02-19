# packages/mm_editor/ios/Classes/engine/ExportEngine.swift

import AVFoundation

class ExportEngine {

    static func export(
        projectJson: [String: Any],
        outputDirectory: String,
        completion: @escaping ([String: Any]) -> Void
    ) {

        guard
            let tracks = projectJson["tracks"] as? [String: Any],
            let videoTrack = tracks["video"] as? [String: Any],
            let clips = videoTrack["clips"] as? [[String: Any]],
            let assets = (projectJson["assets"] as? [String: Any])?["media"] as? [[String: Any]]
        else {
            completion(error("INVALID_ARGUMENT", "Malformed project"))
            return
        }

        let composition = AVMutableComposition()

        guard let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            completion(error("EXPORT_FAILED", "Failed to create video track"))
            return
        }

        // Original audio track (from source videos)
        let compOriginalAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        var currentTime = CMTime.zero

        for clip in clips {
            guard
                let assetId = clip["asset_id"] as? String,
                let source = clip["source"] as? [String: Any],
                let inMs = source["in_ms"] as? Double,
                let outMs = source["out_ms"] as? Double
            else { continue }

            guard
                let assetInfo = assets.first(where: { $0["id"] as? String == assetId }),
                let uri = assetInfo["uri"] as? String,
                let url = URL(string: uri)
            else { continue }

            let asset = AVAsset(url: url)

            let start = CMTime(milliseconds: inMs)
            let duration = CMTime(milliseconds: outMs - inMs)
            let range = CMTimeRange(start: start, duration: duration)

            // Video insert
            if let sourceVideo = asset.tracks(withMediaType: .video).first {
                do {
                    try compVideoTrack.insertTimeRange(range, of: sourceVideo, at: currentTime)
                } catch {
                    completion(error("EXPORT_FAILED", "Video insert failed: \(error.localizedDescription)"))
                    return
                }
            }

            // Original audio insert (if present)
            if let sourceAudio = asset.tracks(withMediaType: .audio).first,
               let compAudio = compOriginalAudioTrack {
                do {
                    try compAudio.insertTimeRange(range, of: sourceAudio, at: currentTime)
                } catch {
                    // Not fatal; some clips might not have audio
                }
            }

            currentTime = currentTime + duration
        }

        // Build audio mix: original + optional music
        let audioMix = AVMutableAudioMix()
        var mixParams: [AVAudioMixInputParameters] = []

        // Original audio gain/fades (optional later; for now constant 1.0)
        if let compAudio = compOriginalAudioTrack {
            let p = AVMutableAudioMixInputParameters(track: compAudio)
            p.setVolume(1.0, at: .zero)
            mixParams.append(p)
        }

        // Optional music track
        if
            let musicTrackConfig = tracks["music"] as? [String: Any],
            let enabled = musicTrackConfig["enabled"] as? Bool, enabled,
            let assetId = musicTrackConfig["asset_id"] as? String,
            let audioAssets = (projectJson["assets"] as? [String: Any])?["audio"] as? [[String: Any]],
            let assetInfo = audioAssets.first(where: { $0["id"] as? String == assetId }),
            let uri = assetInfo["uri"] as? String,
            let url = URL(string: uri)
        {
            let musicAsset = AVAsset(url: url)

            if let musicSourceTrack = musicAsset.tracks(withMediaType: .audio).first,
               let compMusicTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
               )
            {
                // Music timing fields
                let startMs = (musicTrackConfig["start_ms"] as? Double) ?? 0
                let trim = musicTrackConfig["trim_ms"] as? [String: Any]
                let trimInMs = (trim?["in"] as? Double) ?? 0
                let trimOutMs = (trim?["out"] as? Double) ?? 0

                let timelineStart = CMTime(milliseconds: startMs)
                let musicIn = CMTime(milliseconds: trimInMs)

                let wantedDuration = composition.duration - timelineStart
                let srcDuration = musicAsset.duration - musicIn
                let maxDuration = (trimOutMs > 0) ? CMTime(milliseconds: trimOutMs - trimInMs) : srcDuration
                let insertDuration = CMTimeMinimum(wantedDuration, maxDuration)

                let range = CMTimeRange(start: musicIn, duration: insertDuration)

                do {
                    try compMusicTrack.insertTimeRange(range, of: musicSourceTrack, at: timelineStart)
                } catch {
                    completion(error("EXPORT_FAILED", "Music insert failed: \(error.localizedDescription)"))
                    return
                }

                let p = AVMutableAudioMixInputParameters(track: compMusicTrack)

                let gain = (musicTrackConfig["gain"] as? Double) ?? 1.0
                p.setVolume(Float(gain), at: .zero)

                // fades
                if let fade = musicTrackConfig["fade"] as? [String: Any] {
                    let fadeInMs = (fade["in_ms"] as? Double) ?? 0
                    let fadeOutMs = (fade["out_ms"] as? Double) ?? 0

                    if fadeInMs > 0 {
                        p.setVolumeRamp(
                            fromStartVolume: 0.0,
                            toEndVolume: Float(gain),
                            timeRange: CMTimeRange(start: timelineStart, duration: CMTime(milliseconds: fadeInMs))
                        )
                    }
                    if fadeOutMs > 0 {
                        let endStart = composition.duration - CMTime(milliseconds: fadeOutMs)
                        p.setVolumeRamp(
                            fromStartVolume: Float(gain),
                            toEndVolume: 0.0,
                            timeRange: CMTimeRange(start: endStart, duration: CMTime(milliseconds: fadeOutMs))
                        )
                    }
                }

                mixParams.append(p)
            }
        }

        audioMix.inputParameters = mixParams

        // Export
        let outputURL = URL(fileURLWithPath: outputDirectory)
            .appendingPathComponent("mm_export_\(UUID().uuidString).mp4")

        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(error("EXPORT_FAILED", "ExportSession failed"))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.audioMix = audioMix

        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion([
                    "uri": outputURL.absoluteString,
                    "duration_ms": Int(CMTimeGetSeconds(composition.duration) * 1000)
                ])
            } else {
                completion(error("EXPORT_FAILED", exportSession.error?.localizedDescription ?? "Unknown"))
            }
        }
    }

    private static func error(_ code: String, _ message: String) -> [String: Any] {
        return [
            "ok": false,
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }
}

extension CMTime {
    init(milliseconds: Double) {
        self.init(value: CMTimeValue(milliseconds), timescale: 1000)
    }
}

