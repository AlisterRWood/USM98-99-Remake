import Foundation

/// Wall-clock pacing, independent of the simulation speed and random generator.
public struct CommentaryClip:Equatable {
    public var path:String
    public var name:String?
    public init(path:String,name:String?=nil){self.path=path;self.name=name}
}
public struct CommentarySchedule {
    public private(set) var current:CommentaryClip?
    public private(set) var pending:[CommentaryClip]=[]
    public private(set) var kind:String?
    private var lastSpeech = -Double.infinity
    private var lastName:String?
    private var lastNameTime = -Double.infinity
    private var shots=0
    private var lastShotSound = -Double.infinity
    public init(){}
    public mutating func clear(){current=nil;pending=[];kind=nil}
    public mutating func changeSpeed(_ speed:Double)->Bool {
        if speed>1 && kind != "goal" {let active=current != nil || !pending.isEmpty;clear();return active}
        return false
    }
    public func allows(_ event:String,speed:Double,now:Double)->Bool {
        if event=="goal" {return true}
        guard speed<=1,current==nil,pending.isEmpty else{return false}
        return now-lastSpeech >= (event=="shot" ? 18:7)
    }
    /// Returns true only when an existing phrase should be stopped. A spoken name finishes intact.
    public mutating func enqueue(_ event:String,now:Double,name:CommentaryClip?,phrase:String)->Bool {
        let preserveName=event=="goal" && current?.name != nil
        let interrupt=event=="goal" && current != nil && !preserveName
        if event=="goal" {pending=[];if !preserveName {current=nil}}
        if let name,!(name.name==lastName && now-lastNameTime<10),name.name != current?.name {pending.append(name)}
        pending.append(CommentaryClip(path:phrase));kind=event;lastSpeech=now
        return interrupt
    }
    public mutating func next(now:Double)->CommentaryClip? {
        current=nil
        guard !pending.isEmpty else {kind=nil;return nil}
        let clip=pending.removeFirst();current=clip
        if let name=clip.name {lastName=name;lastNameTime=now}
        return clip
    }
    public mutating func shotSound(speed:Double,now:Double)->Bool {
        guard speed<=1 else{return false}
        shots+=1
        guard shots%3==1,now-lastShotSound>=8 else{return false}
        lastShotSound=now;return true
    }
}
