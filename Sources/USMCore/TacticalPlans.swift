import Foundation
public struct TacticalInstruction:Codable,Equatable {
    public var point:FieldPoint
    public var action:String
    public var targetSlot:Int
    public init(point:FieldPoint,action:String="Move",targetSlot:Int=9){self.point=point;self.action=action;self.targetSlot=targetSlot}
}
public struct TacticalPlan:Codable,Equatable {
    public var name="Custom plan"
    public var states:[String:[TacticalInstruction]]=[:]
    public init(){}
    public static var situations:[String] {(0..<12).map{"Attack zone \($0+1)"}+(0..<12).map{"Defend zone \($0+1)"}+["Attacking left corner","Defending left corner","Attacking right corner","Defending right corner","Attacking goal kick","Defending goal kick","Attacking kick off","Defending kick off","Attacking penalty","Defending penalty","Attacking free kick","Defending free kick"]}
    public static func defaults(_ tactics:Tactics)->[TacticalInstruction] {
        var result=[TacticalInstruction(point:FieldPoint(5,34))]
        let parts=tactics.formation.split(separator:"-").compactMap{Int($0)}
        for row in 0..<3 {for n in 0..<parts[row] {result.append(TacticalInstruction(point:FieldPoint(Double(25+row*25),68*Double(n+1)/Double(parts[row]+1))))}}
        return result
    }
}
