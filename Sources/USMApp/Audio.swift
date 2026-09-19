import Foundation
import AVFoundation
import USMCore

@MainActor final class GameAudio {
    var music: AVAudioPlayer?
    var crowd: AVAudioPlayer?
    // Retain and reuse players. Polling isPlaying while releasing finished
    // players in removeAll crashed inside AVFoundation on macOS 26.6.2.
    var effects: [String:AVAudioPlayer] = [:]
    var lastEffectTime: [String:Double] = [:]
    struct SpeechIndex:Decodable {var groups:[String:[String]];var names:[String:[String:String]]}
    var voice:AVAudioPlayer?
    var speech=CommentarySchedule()
    var playbackSpeed=1.0
    var variation=0
    lazy var speechIndex:SpeechIndex? = {guard let url=Bundle.module.url(forResource:"index",withExtension:"json",subdirectory:"Resources/Commentary"),let data=try? Data(contentsOf:url) else{return nil};return try? JSONDecoder().decode(SpeechIndex.self,from:data)}()
    func stopSpeech(){voice?.stop();voice=nil;speech.clear()}
    func setPlaybackSpeed(_ speed:Double){playbackSpeed=speed;if speech.changeSpeed(speed){voice?.stop();voice=nil}}
    func serviceCommentary(){
        guard enabled else{stopSpeech();return}
        guard voice?.isPlaying != true else{return}
        guard let clip=speech.next(now:ProcessInfo.processInfo.systemUptime) else{return}
        guard let root=Bundle.module.url(forResource:"Commentary",withExtension:nil,subdirectory:"Resources"),let player=try? AVAudioPlayer(contentsOf:root.appendingPathComponent(clip.path)) else{return}
        voice=player;player.volume=0.9;player.play()
    }
    func commentary(_ kind:String,name:String?=nil){
        let now=ProcessInfo.processInfo.systemUptime
        guard enabled,speech.allows(kind,speed:playbackSpeed,now:now) else{return}
        let groups=["goal":"goal","shot":"shooting","save":"saves","miss":"badmiss","corner":"corner","free kick":"freekick","penalty":"penalty","foul":"badfoul","yellow":"yellow","red":"red_card","offside":"offside","pass":"passing","tackle":"tackle","interception":"badpass","cross":"cross","dribble":"dribble","substitution":"sub"]
        guard let group=groups[kind],let clips=speechIndex?.groups[group],!clips.isEmpty else{return}
        var spokenName:CommentaryClip?
        if let name=name {
            let normalized=name.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"en_US_POSIX")).lowercased()
            let words=normalized.split(separator:" ");let mode=["goal","shot"].contains(kind) ? "shouting":"talking"
            for start in words.indices {
                let key=words[start...].joined().filter{$0.isASCII && $0.isLetter}
                if let clip=speechIndex?.names[mode]?[key]{spokenName=CommentaryClip(path:clip,name:normalized);break}
            }
        }
        if speech.enqueue(kind,now:now,name:spokenName,phrase:clips[variation%clips.count]) {voice?.stop();voice=nil}
        variation+=1;serviceCommentary()
    }
    var enabled=true {didSet{if !enabled {stopSpeech();crowd?.pause();effects.values.forEach{$0.stop()}}}}
    var musicEnabled=true
    func url(_ name:String)->URL? { Bundle.module.url(forResource:name,withExtension:"wav",subdirectory:"Resources/SFX") }
    func play(_ name:String,volume:Float=0.5) {
        guard enabled,let url=url(name) else {return}
        do {
            let now=ProcessInfo.processInfo.systemUptime
            guard now-(lastEffectTime[name] ?? -Double.infinity)>=0.12 else{return}
            let player:AVAudioPlayer
            if let cached=effects[name] {player=cached;player.stop();player.currentTime=0}
            else {player=try AVAudioPlayer(contentsOf:url);player.prepareToPlay();effects[name]=player}
            lastEffectTime[name]=now
            player.volume=volume;player.play()
        } catch { NSLog("USM audio: %@",error.localizedDescription) }
    }
    func startMusic() {
        guard musicEnabled else {return}
        if music==nil,let url=Bundle.module.url(forResource:"original-music",withExtension:"wav",subdirectory:"Resources") {
            music=try? AVAudioPlayer(contentsOf:url);music?.numberOfLoops = -1;music?.volume=0.23
        }
        music?.play()
    }
    func stop() {
        music?.stop();music=nil
        crowd?.stop();crowd=nil
        effects.values.forEach{$0.stop()};effects.removeAll()
        stopSpeech()
    }
    func matchAmbience(_ on:Bool) {
        if on {
            music?.pause()
            if crowd==nil,let url=url("background") {crowd=try? AVAudioPlayer(contentsOf:url);crowd?.numberOfLoops = -1;crowd?.volume=0.22}
            if enabled {crowd?.play()}
        } else {stopSpeech();crowd?.stop();startMusic()}
    }
    func event(_ kind:String) {
        switch kind {
        case "free kick","offside","penalty":play("mt_whishort",volume:0.65)
        case "end whistle":play("mt_whis3",volume:0.7)
        case "whistle":play("mt_whislong",volume:0.45)
        case "pass":play("mt_passing",volume:0.28)
        case "shot":if speech.shotSound(speed:playbackSpeed,now:ProcessInfo.processInfo.systemUptime){play("mt_kicking",volume:0.35)}
        case "goal":play("mt_bigroar",volume:0.8)
        case "save":play("mt_bigaah",volume:0.55)
        case "miss":play("mt_bigooh",volume:0.5)
        default:break
        }
    }
}
