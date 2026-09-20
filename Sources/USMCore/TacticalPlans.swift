import Foundation
public enum SetPieceRoutineKind:String,Codable,CaseIterable {
    case nearPostCross,farPostCross,shortCorner,directShot,whippedCross,layoff,shortDistribution,wideDistribution,longDistribution
}
public struct SetPieceRoutine:Codable,Equatable {
    public var kind:SetPieceRoutineKind
    public var targetSlot:Int?
    public init(kind:SetPieceRoutineKind,targetSlot:Int?=nil){self.kind=kind;self.targetSlot=targetSlot}
}
public struct TacticalInstruction:Codable,Equatable {
    public var point:FieldPoint
    public var action:String
    public var targetSlot:Int
    public init(point:FieldPoint,action:String="Move",targetSlot:Int=9){self.point=point;self.action=action;self.targetSlot=targetSlot}
}
public struct TacticalPlan:Codable,Equatable {
    public var name="Custom plan"
    public var states:[String:[TacticalInstruction]]=[:]
    public var setPieceRoutines:[String:SetPieceRoutine]=[:]
    public init(){}
    enum CodingKeys:String,CodingKey {case name,states,setPieceRoutines}
    public init(from decoder:Decoder) throws {
        let values=try decoder.container(keyedBy:CodingKeys.self)
        name=try values.decodeIfPresent(String.self,forKey:.name) ?? "Custom plan"
        states=try values.decodeIfPresent([String:[TacticalInstruction]].self,forKey:.states) ?? [:]
        setPieceRoutines=try values.decodeIfPresent([String:SetPieceRoutine].self,forKey:.setPieceRoutines) ?? [:]
    }
    public static func setPieceKey(_ restart:String)->String {
        switch restart.lowercased() {
        case "left corner","right corner","free kick","goal kick": return restart.lowercased()
        default:return restart.lowercased()
        }
    }
    public static var situations:[String] {(0..<12).map{"Attack zone \($0+1)"}+(0..<12).map{"Defend zone \($0+1)"}+["Attacking left corner","Defending left corner","Attacking right corner","Defending right corner","Attacking goal kick","Defending goal kick","Attacking kick off","Defending kick off","Attacking penalty","Defending penalty","Attacking free kick","Defending free kick"]}
    public static func defaults(_ tactics:Tactics)->[TacticalInstruction] {
        var result=[TacticalInstruction(point:FieldPoint(5,34))]
        let parts=tactics.formation.split(separator:"-").compactMap{Int($0)}
        for row in 0..<3 {for n in 0..<parts[row] {result.append(TacticalInstruction(point:FieldPoint(Double(25+row*25),68*Double(n+1)/Double(parts[row]+1))))}}
        return result
    }
}
