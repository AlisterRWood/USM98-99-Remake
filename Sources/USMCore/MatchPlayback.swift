import Foundation

public struct MatchPlayback {
    public private(set) var popup: LiveEvent?
    public private(set) var remaining = 0.0
    public private(set) var accumulator = 0.0
    private var fixtureID: String?

    public init() {}

    public mutating func reset() {
        popup=nil;remaining=0;accumulator=0;fixtureID=nil
    }

    public mutating func advance(_ match: inout LiveMatch, realSeconds: Double, speed: Double, running: Bool) {
        if fixtureID != match.fixtureID {
            reset();fixtureID=match.fixtureID
        }
        let pace=speed.isFinite ? min(16,max(1,speed)):1
        if popup != nil {
            let elapsed=realSeconds.isFinite ? max(0,realSeconds):0
            remaining=max(0,remaining-elapsed*pace)
            if remaining <= 0.000001 {popup=nil;remaining=0}
            return
        }
        guard running,match.phase == .firstHalf || match.phase == .secondHalf else {accumulator=0;return}
        accumulator += pace
        while accumulator >= 1 {
            let before=match.events.count
            match.step(0.1);accumulator -= 1
            if let event=match.events.dropFirst(before).last(where:{["yellow","red","goal"].contains($0.kind)}) {
                popup=event;remaining=event.kind == "goal" ? 2.4:1.8;accumulator=0
                break
            }
            if match.phase == .halfTime || match.isFinished {accumulator=0;break}
        }
    }
}
