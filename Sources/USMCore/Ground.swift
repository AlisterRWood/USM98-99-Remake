import Foundation

public struct GroundPlot:Identifiable,Equatable {
    public var id:String
    public var x:Double
    public var z:Double
    public var stand:Bool
    public init(id:String,x:Double,z:Double,stand:Bool=false) {self.id=id;self.x=x;self.z=z;self.stand=stand}
    public static var all:[GroundPlot] {
        var plots:[GroundPlot]=[
            GroundPlot(id:"north",x:0,z:-46,stand:true),GroundPlot(id:"south",x:0,z:46,stand:true),
            GroundPlot(id:"east",x:64,z:0,stand:true),GroundPlot(id:"west",x:-64,z:0,stand:true),
            GroundPlot(id:"north-east",x:64,z:-46,stand:true),GroundPlot(id:"north-west",x:-64,z:-46,stand:true),
            GroundPlot(id:"south-east",x:64,z:46,stand:true),GroundPlot(id:"south-west",x:-64,z:46,stand:true)
        ]
        for (col,x) in stride(from:-126.0,through:126,by:28).enumerated() {
            for (row,z) in stride(from:-98.0,through:98,by:28).enumerated() {
                if abs(x)>=98 || abs(z)>=70 {plots.append(GroundPlot(id:"plot-\(col)-\(row)",x:x,z:z))}
            }
        }
        return plots
    }
}
public struct GroundBuilding:Codable,Identifiable,Equatable {
    public var id:String
    public var plotID:String
    public var kind:String
    public var level:Int
    public var rotation:Int
    public var capacity:Int
    public var dueWeek:Int?
    public var targetLevel:Int?
    public var specification:StandSpecification?
    public init(id:String=UUID().uuidString,plotID:String,kind:String,level:Int=1,rotation:Int=0,capacity:Int=0,dueWeek:Int?=nil) {
        self.id=id;self.plotID=plotID;self.kind=kind;self.level=level;self.rotation=rotation;self.capacity=capacity;self.dueWeek=dueWeek
    }
    public var isBuilding:Bool {dueWeek != nil}
    public var plot:GroundPlot {GroundPlot.all.first{$0.id==plotID}!}
    public var title:String {kind=="Stand" ? "\(plotID.capitalized) stand":kind}
    public var destination:String {
        switch kind {
        case "Manager’s office","Boardroom","Dressing room","Business office","Transfer office":return kind
        case "Shop","Programme stall","Small shop","Large shop":return "Merchandise"
        case "Café","Burger bar","Restaurant":return "Catering"
        case "Training":return "Team training"
        default:return "Stadium development"
        }
    }
}
public enum GroundRules {
    public static let buildable=["Stand","Programme stall","Small shop","Shop","Large shop","Burger bar","Café","Restaurant","Car park","Training"]
    public static func cost(_ kind:String,level:Int=1)->Int {
        switch kind {case "Stand":return 1_500_000*level;case "Programme stall":return 15000;case "Small shop":return 75000;case "Large shop":return 650000;case "Burger bar":return 45000;case "Restaurant":return 500000;case "Car park":return 100000;case "Shop":return 400_000;case "Café":return 300_000;case "Training":return 750_000;default:return 0}
    }
    public static func weeks(_ kind:String)->Int {kind=="Stand" ? 4:3}
    public static func initial(capacity:Int)->[GroundBuilding] {
        var items=["north","south","east","west"].enumerated().map {i,id in GroundBuilding(id:id,plotID:id,kind:"Stand",capacity:capacity/4+(i==0 ? capacity%4:0))}
        for (id,plot,kind) in [
            ("chairman","plot-1-1","Boardroom"),("manager","plot-4-0","Manager’s office"),
            ("dressing","plot-8-4","Dressing room"),("business","plot-0-3","Business office"),
            ("transfers","plot-9-2","Transfer office"),("shop","plot-1-6","Shop"),
            ("cafe","plot-8-6","Café"),("training","plot-7-0","Training")
        ] {items.append(GroundBuilding(id:id,plotID:plot,kind:kind))}
        return items
    }
}
extension Career {
    public var groundBuildings:[GroundBuilding] {ground ?? GroundRules.initial(capacity:capacity)}
    public mutating func initializeGround() {if ground==nil {ground=GroundRules.initial(capacity:capacity)}}
    @discardableResult public mutating func placeBuilding(kind:String,plotID:String)->Bool {
        initializeGround()
        guard GroundRules.buildable.contains(kind),let plot=GroundPlot.all.first(where:{$0.id==plotID}),
              plot.stand==(kind=="Stand"),!ground!.contains(where:{$0.plotID==plotID}),cash>=GroundRules.cost(kind) else {return false}
        if kind=="Stand",plotID.contains("-") {
            let neighbours=plotID.split(separator:"-").map(String.init)
            guard neighbours.allSatisfy({id in ground!.contains{$0.plotID==id && $0.kind=="Stand" && !$0.isBuilding}}) else{return false}
        }
        transact("Build \(kind)",-GroundRules.cost(kind))
        ground!.append(GroundBuilding(plotID:plotID,kind:kind,level:0,dueWeek:week+GroundRules.weeks(kind)))
        post("DEVELOPMENT","\(kind) construction begins","New facility at \(plotID). Completion in \(GroundRules.weeks(kind)) weeks.")
        return true
    }
    @discardableResult public mutating func upgradeBuilding(_ id:String)->Bool {
        initializeGround()
        guard let i=ground!.firstIndex(where:{$0.id==id}),!ground![i].isBuilding,GroundRules.buildable.contains(ground![i].kind) else {return false}
        let cost=GroundRules.cost(ground![i].kind,level:ground![i].level)
        guard cash>=cost else {return false}
        let name=ground![i].title
        ground![i].targetLevel=ground![i].level+1
        ground![i].dueWeek=week+GroundRules.weeks(ground![i].kind)
        transact("Upgrade \(name)",-cost);post("DEVELOPMENT","\(name) expansion begins","The existing facility stays open while its extension is built.")
        return true
    }
    @discardableResult public mutating func moveBuilding(_ id:String,to plotID:String)->Bool {
        initializeGround()
        guard let i=ground!.firstIndex(where:{$0.id==id}),ground![i].kind != "Stand",!ground![i].isBuilding,
              let p=GroundPlot.all.first(where:{$0.id==plotID}),!p.stand,!ground!.contains(where:{$0.plotID==plotID}) else {return false}
        ground![i].plotID=plotID;return true
    }
    public mutating func rotateBuilding(_ id:String) {
        initializeGround()
        guard let i=ground!.firstIndex(where:{$0.id==id}),ground![i].kind != "Stand" else {return}
        ground![i].rotation=(ground![i].rotation+1)%4
    }
    @discardableResult public mutating func demolishBuilding(_ id:String)->Bool {
        initializeGround()
        guard let i=ground!.firstIndex(where:{$0.id==id}),GroundRules.buildable.contains(ground![i].kind),!ground![i].isBuilding else {return false}
        if ground![i].kind=="Stand",!ground![i].plotID.contains("-"),ground!.contains(where:{$0.kind=="Stand" && $0.plotID.contains(ground![i].plotID+"-") || $0.kind=="Stand" && $0.plotID.hasSuffix("-"+ground![i].plotID)}) {return false}
        let building=ground!.remove(at:i)
        if building.kind=="Stand" {capacity=max(0,capacity-building.capacity)}
        if ["Shop","Small shop","Large shop","Programme stall","Café","Burger bar","Restaurant"].contains(building.kind) {shops=max(0,shops-building.level)}
        if building.kind=="Training" {facilities=max(0,facilities-building.level)}
        transact("Salvage: \(building.title)",GroundRules.cost(building.kind)/10)
        return true
    }
    public mutating func progressGround() {
        guard var items=ground else {return}
        for i in items.indices {
            guard let due=items[i].dueWeek,due<=week else {continue}
            let old=items[i].level;items[i].level=items[i].targetLevel ?? max(1,old+1)
            let increase=items[i].level-old
            if items[i].kind=="Stand" {
                if var spec=items[i].specification,let target=spec.targetCapacity {
                    capacity += target-items[i].capacity;items[i].capacity=target
                    spec.seated=spec.targetSeated ?? spec.seated;spec.covered=spec.targetCovered ?? spec.covered;spec.boxes=spec.targetBoxes ?? spec.boxes;spec.condition=100
                    spec.targetCapacity=nil;spec.targetSeated=nil;spec.targetCovered=nil;spec.targetBoxes=nil;items[i].specification=spec
                }else{items[i].capacity += 5000*increase;capacity += 5000*increase}
            }
            if ["Shop","Small shop","Large shop","Programme stall","Café","Burger bar","Restaurant"].contains(items[i].kind) {shops += increase}
            if items[i].kind=="Training" {facilities += increase}
            items[i].dueWeek=nil;items[i].targetLevel=nil
            post("DEVELOPMENT","\(items[i].title) is now open","Your ground has changed. Visit the stadium to see the completed project.")
        }
        ground=items
    }
}
