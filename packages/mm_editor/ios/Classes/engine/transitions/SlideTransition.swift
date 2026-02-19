# packages/mm_editor/ios/Classes/engine/transitions/SlideTransition.swift

class SlideTransition: Transition {

    enum Direction {
        case left
        case right
    }

    let direction: Direction

    init(direction: Direction) {
        self.direction = direction
    }

    func apply(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        fromTrack: AVCompositionTrack,
        toTrack: AVCompositionTrack,
        timeRange: CMTimeRange,
        renderSize: CGSize
    ) {

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange

        let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: fromTrack)
        let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: toTrack)

        let width = renderSize.width

        let offset = (direction == .left) ? -width : width

        fromLayer.setTransformRamp(
            fromStart: .identity,
            toEnd: CGAffineTransform(translationX: offset, y: 0),
            timeRange: timeRange
        )

        toLayer.setTransformRamp(
            fromStart: CGAffineTransform(translationX: -offset, y: 0),
            toEnd: .identity,
            timeRange: timeRange
        )

        instruction.layerInstructions = [toLayer, fromLayer]
        videoComposition.instructions.append(instruction)
    }
}
