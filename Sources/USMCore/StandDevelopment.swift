import Foundation

public struct StandSpecification:Codable,Equatable {
    public var seated=true,covered=true
    public var boxes=0,condition=100
    public var targetCapacity:Int?
    public var targetSeated:Bool?
    public var targetCovered:Bool?
    public var targetBoxes:Int?
    public init(){}
}
public extension Career {
    var availableCapacity:Int {max(0,capacity-groundBuildings.filter{$0.kind=="Stand" && $0.isBuilding}.reduce(0){$0+$1.capacity})}
    func standQuote(_ id:String,capacity requested:Int,seated:Bool,covered:Bool,boxes:Int)->Int? {
        guard let b=groundBuildings.first(where:{$0.id==id && $0.kind=="Stand" && !$0.isBuilding}) else{return nil}
        if b.plotID.contains("-") && boxes>0 {return nil}
        let s=b.specification ?? StandSpecification()
        guard requested>=b.capacity,requested<=40000,boxes>=s.boxes,boxes<=50,(!s.seated || seated) else{return nil}
        let cost=(requested-b.capacity)*(seated ? 300:150)+(seated && !s.seated ? b.capacity*100:0)+(covered && !s.covered ? requested*80:0)+(!covered && s.covered ? b.capacity*20:0)+(boxes-s.boxes)*80000
        return cost>0 ? cost:nil
    }
    @discardableResult mutating func developStand(_ id:String,capacity requested:Int,seated:Bool,covered:Bool,boxes:Int)->Bool {
        initializeGround();guard let cost=standQuote(id,capacity:requested,seated:seated,covered:covered,boxes:boxes),cash>=cost,let i=ground!.firstIndex(where:{$0.id==id}) else{return false}
        var spec=ground![i].specification ?? StandSpecification();spec.targetCapacity=requested;spec.targetSeated=seated;spec.targetCovered=covered;spec.targetBoxes=boxes;ground![i].specification=spec
        ground![i].dueWeek=week+max(2,(requested-ground![i].capacity)/2000+2);ground![i].targetLevel=ground![i].level+1
        transact("Stand development: \(ground![i].title)",-cost);post("DEVELOPMENT","Stand closed for works","The stand is unavailable until construction completes. Available capacity: \(availableCapacity.formatted()).");return true
    }
    @discardableResult mutating func maintainStand(_ id:String)->Bool {
        initializeGround();guard let i=ground!.firstIndex(where:{$0.id==id && $0.kind=="Stand" && !$0.isBuilding}) else{return false}
        var s=ground![i].specification ?? StandSpecification();let cost=(100-s.condition)*ground![i].capacity/10;guard cost>0,cash>=cost else{return false};s.condition=100;ground![i].specification=s;transact("Stand maintenance",-cost);return true
    }
}

public struct StandAppearance:Equatable {
    public let decks:Int,rowsPerDeck:Int
    public let label:String
    public init(capacity:Int){
        switch capacity {
        case ..<5000:decks=1;rowsPerDeck=5;label="Small stand"
        case ..<10000:decks=1;rowsPerDeck=10;label="Medium stand"
        case ..<15000:decks=2;rowsPerDeck=8;label="Large two-tier stand"
        default:decks=3;rowsPerDeck=7;label="Grand three-tier stand"
        }
    }
}
