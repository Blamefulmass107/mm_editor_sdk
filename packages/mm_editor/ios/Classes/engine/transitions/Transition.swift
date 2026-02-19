# packages/mm_editor/ios/Classes/engine/transitions/Transition.swift

import AVFoundation
import CoreGraphics

protocol Transition {
    func apply(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        fromTrack: AVCompositionTrack,
        toTrack: AVCompositionTrack,
        timeRange: CMTimeRange,
        renderSize: CGSize
    )
}
