# packages/mm_editor/ios/Classes/engine/transitions/TransitionFactory.swift

import Foundation

enum TransitionType: String {
    case crossfade = "crossfade"
    case dipBlack  = "dip_black"
    case dipWhite  = "dip_white"
    case wipeLR    = "wipe_lr"
    case slideLR   = "slide_lr"
    case slideRL   = "slide_rl"
}

final class TransitionFactory {
    static func make(type: String) -> Transition {
        switch TransitionType(rawValue: type) {
        case .crossfade: return CrossfadeTransition()
        case .dipBlack:  return DipBlackTransition()
        case .dipWhite:  return DipWhiteTransition()
        case .wipeLR:    return WipeLRTransition()   // (approx, see note below)
        case .slideLR:   return SlideTransition(direction: .left)
        case .slideRL:   return SlideTransition(direction: .right)
        case .none:      return CrossfadeTransition()
        }
    }
}
