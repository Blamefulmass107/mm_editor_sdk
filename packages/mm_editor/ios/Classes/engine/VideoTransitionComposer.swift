# packages/mm_editor/ios/Classes/engine/VideoTransitionComposer.swift

import AVFoundation

struct VideoTransitionComposer {
  static func build(
    projectJson: [String: Any],
    composition: AVMutableComposition,
    clips: [[String: Any]],
    assets: [[String: Any]]
  ) throws -> AVMutableVideoComposition
}
