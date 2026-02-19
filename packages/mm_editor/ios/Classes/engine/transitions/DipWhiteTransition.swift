# packages/mm_editor/ios/Classes/engine/transitions/DipWhiteTransition.swift

import AVFoundation
import UIKit

final class DipWhiteTransition: Transition {

    func apply(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        fromTrack: AVCompositionTrack,
        toTrack: AVCompositionTrack,
        timeRange: CMTimeRange,
        renderSize: CGSize
    ) {
        // Set background color here
        videoComposition.backgroundColor = UIColor.white.cgColor

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange

        let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: fromTrack)
        let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: toTrack)

        let half = CMTimeMultiplyByFloat64(timeRange.duration, multiplier: 0.5)

        fromLayer.setOpacityRamp(
            fromStartOpacity: 1.0,
            toEndOpacity: 0.0,
            timeRange: CMTimeRange(start: timeRange.start, duration: half)
        )

        toLayer.setOpacityRamp(
            fromStartOpacity: 0.0,
            toEndOpacity: 1.0,
            timeRange: CMTimeRange(start: timeRange.start + half, duration: half)
        )

        instruction.layerInstructions = [toLayer, fromLayer]
        videoComposition.instructions.append(instruction)
    }
}
