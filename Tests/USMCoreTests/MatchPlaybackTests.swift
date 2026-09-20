import Foundation
import USMCore

extension CareerTests {
    func testMatchPopupsPauseAndScaleWithSpeed() throws {
        let c=try career(),fixture=try XCTUnwrap(c.nextFixture)
        var seen=Set<String>()
        for seed in 1...12 {
            var match=LiveMatch(career:c,fixture:fixture)
            match.rng=RNG(seed:UInt64(seed));match.homeTactics.tackling="Hard";match.awayTactics.tackling="Hard";match.startHalf()
            var playback=MatchPlayback()
            for _ in 0..<900 where !match.isFinished {
                playback.advance(&match,realSeconds:1.0/30,speed:16,running:true)
                guard let popup=playback.popup else {continue}
                if !seen.contains(popup.kind) {
                    seen.insert(popup.kind)
                    for speed in [1.0,2,4,8,16] {
                        var copy=match,clock=playback
                        let duration=clock.remaining/speed
                        clock.advance(&copy,realSeconds:duration*0.5,speed:speed,running:true)
                        XCTAssertTrue(clock.popup != nil)
                        XCTAssertEqual(copy.elapsed,match.elapsed)
                        XCTAssertEqual(copy.ball,match.ball)
                        XCTAssertEqual(copy.players,match.players)
                        XCTAssertEqual(copy.events,match.events)
                        XCTAssertEqual(copy.physicsTime,match.physicsTime)
                        XCTAssertEqual(copy.rng.state,match.rng.state)
                        clock.advance(&copy,realSeconds:duration*0.5,speed:speed,running:true)
                        XCTAssertNil(clock.popup)
                        XCTAssertEqual(copy.elapsed,match.elapsed)
                        clock.advance(&copy,realSeconds:1.0/30,speed:speed,running:false)
                        XCTAssertEqual(copy.elapsed,match.elapsed)
                        clock.advance(&copy,realSeconds:1.0/30,speed:speed,running:true)
                        XCTAssertTrue(copy.elapsed>match.elapsed)
                        XCTAssertTrue(copy.elapsed-match.elapsed <= speed*0.8+0.00001)
                    }
                }
                playback.advance(&match,realSeconds:3,speed:16,running:true)
                if seen == Set(["yellow","red","goal"]) {break}
            }
            if seen == Set(["yellow","red","goal"]) {break}
        }
        XCTAssertEqual(seen,Set(["yellow","red","goal"]))
    }

    func testMatchPopupStopsFastBatchAndRespectsManualPause() throws {
        let c=try career(),fixture=try XCTUnwrap(c.nextFixture)
        var observed=false
        for seed in 1...40 {
            var match=LiveMatch(career:c,fixture:fixture);match.startHalf();match.rng=RNG(seed:UInt64(seed))
            let shooter=try XCTUnwrap(match.players.first{$0.side==0 && $0.slot==10})
            match.owner=nil;match.ball=FieldPoint(94,34)
            match.flight=BallFlight(from:match.ball,target:FieldPoint(105,34),progress:0.99,duration:0.1,kind:"shot",kicker:shooter.id,receiver:nil,side:0,onTarget:true)
            var clock=MatchPlayback()
            let before=match.physicsTime
            clock.advance(&match,realSeconds:1.0/30,speed:16,running:true)
            guard clock.popup?.kind == "goal" else {continue}
            observed=true
            XCTAssertTrue(abs(match.physicsTime-before-0.1)<0.000001)
            XCTAssertEqual(clock.accumulator,0)
            let elapsed=match.elapsed,ball=match.ball
            clock.advance(&match,realSeconds:0.05,speed:1,running:false)
            XCTAssertTrue(clock.popup != nil)
            clock.advance(&match,realSeconds:0.15,speed:16,running:false)
            XCTAssertNil(clock.popup)
            XCTAssertEqual(match.elapsed,elapsed);XCTAssertEqual(match.ball,ball)
            clock.advance(&match,realSeconds:1,speed:16,running:false)
            XCTAssertEqual(match.elapsed,elapsed)
            clock.advance(&match,realSeconds:1.0/30,speed:1,running:true)
            XCTAssertTrue(abs(match.elapsed-elapsed-0.8)<0.000001)
            clock.reset();XCTAssertNil(clock.popup);XCTAssertEqual(clock.accumulator,0)
            break
        }
        XCTAssertTrue(observed)
    }
}
