import Foundation
import USMCore

// Compile with Audio.swift, the generated resource_bundle_accessor.swift and USMCore.o.
// Exercises the actual audio implementation through three complete matches.
@main struct VerifyMatchAudio {
    @MainActor static func main() async throws {
        let root=Bundle.module.url(forResource:"Resources",withExtension:nil)!
        let database=try Database.load(root.appendingPathComponent("database.json"))
        let audio=GameAudio()
        audio.musicEnabled=false
        for speed in [1.0,8.0,32.0] {
            var career=Career(database:database,clubID:database.clubs[0].id,manager:"Audio QA")
            career.initializeManagement()
            let fixture=career.fixtures.first{$0.home==career.clubID || $0.away==career.clubID}!
            var match=LiveMatch(career:career,fixture:fixture)
            audio.matchAmbience(true)
            audio.setPlaybackSpeed(speed)
            match.startHalf()
            var tick=0
            while !match.isFinished {
                let count=match.events.count
                for _ in 0..<120 {match.step(0.1);if match.phase == .halfTime {match.startHalf()}}
                for event in match.events.dropFirst(count) {
                    audio.event(event.kind)
                    audio.commentary(event.kind,name:event.playerID.flatMap{id in match.players.first{$0.id==id}?.name})
                }
                audio.serviceCommentary()
                if tick%30==0 {audio.enabled=false;audio.enabled=true}
                tick+=1
                try await Task.sleep(for:.milliseconds(10))
            }
            audio.matchAmbience(false)
            print("PASS complete audio match at \(speed)x: \(match.events.count) events; \(audio.effects.count) retained effect players")
        }
        precondition(audio.effects.count<=10,"Effect pool must stay bounded by clip name")
        audio.enabled=false
        print("PASS audio reuse, mute/unmute, commentary and end-of-match cleanup")
    }
}
