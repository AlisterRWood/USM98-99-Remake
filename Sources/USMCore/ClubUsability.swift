import Foundation

public struct SavedFormation:Codable,Identifiable {
    public var id:String {name}
    public var name:String
    public var formation:String
    public var positions:[FieldPoint]?
    public var plan:TacticalPlan?
}
public extension StaffMember {
    func trainingEffectiveness(skill:Int)->Double {
        let skills=["Keeping":[0],"Defending":[1,5],"Passing":[2,8],"Shooting":[3,7],"Fitness":[4,6]]
        return Double(quality)/100*((skills[speciality] ?? []).contains(skill) ? 1.25:0.65)
    }
    var assignmentLabel:String {"\(name) · \(speciality) · \(quality)/100"}
}
public extension Career {
    @discardableResult mutating func saveFormation(named raw:String)->Bool {
        let name=String(raw.trimmingCharacters(in:.whitespacesAndNewlines).prefix(40));guard !name.isEmpty else{return false}
        initializeManagement();var library=management!.savedFormations ?? []
        library.removeAll{$0.name.caseInsensitiveCompare(name) == .orderedSame}
        library.append(SavedFormation(name:name,formation:tactics.formation,positions:tactics.customPositions,plan:tactics.plan))
        management!.savedFormations=library;return true
    }
    @discardableResult mutating func loadFormation(named name:String)->Bool {
        guard let item=management?.savedFormations?.first(where:{$0.name==name}) else{return false}
        tactics.formation=item.formation;tactics.customPositions=item.positions;tactics.plan=item.plan;return true
    }
    mutating func deleteFormation(named name:String){management?.savedFormations?.removeAll{$0.name==name}}
    func canRelease(_ id:String)->Bool {
        activeMatch==nil && squad.count>16 && squad.contains{$0.id==id} && !(management?.loans.contains{$0.playerID==id} ?? false)
    }
    @discardableResult mutating func listPlayer(_ id:String,askingPrice:Int)->Bool {
        guard canRelease(id),(1...999_999_999).contains(askingPrice) else{return false};initializeManagement()
        management!.listed[id]=askingPrice;management!.loanListed?.removeValue(forKey:id);return true
    }
    @discardableResult mutating func listPlayerForLoan(_ id:String,weeks:Int)->Bool {
        guard canRelease(id),(4...52).contains(weeks) else{return false};initializeManagement()
        if management!.loanListed==nil{management!.loanListed=[:]};management!.loanListed![id]=weeks;management!.listed.removeValue(forKey:id);return true
    }
    mutating func unlistPlayer(_ id:String){management?.listed.removeValue(forKey:id);management?.loanListed?.removeValue(forKey:id)}
    func fastSaleValue(_ id:String)->Int {guard canRelease(id),let p=squad.first(where:{$0.id==id}) else{return 0};return max(1,p.value*60/100)}
    @discardableResult mutating func fastSell(_ id:String)->Bool {
        let fee=fastSaleValue(id);guard fee>0,let index=players.firstIndex(where:{$0.id==id}) else{return false}
        let buyers=clubs.filter{$0.id != clubID && $0.country==club.country};guard !buyers.isEmpty else{return false}
        initializeManagement();let buyer=buyers[rng.int(0...buyers.count-1)],name=players[index].name
        players[index].clubID=buyer.id;transact("Fast sale: \(name)",fee);clearDepartingPlayer(id)
        for i in management!.negotiations.indices where management!.negotiations[i].playerID==id && !management!.negotiations[i].closed {management!.negotiations[i].stage="Withdrawn";management!.negotiations[i].closedWeek=management!.elapsed}
        autoSelect();post("TRANSFER","\(name) sold to \(buyer.name)","Immediate payment: £\(fee.formatted()) (60% of valuation).");return true
    }
    mutating func clearDepartingPlayer(_ id:String){
        lineup.removeAll{$0==id};squadOrder?.removeAll{$0==id};unlistPlayer(id)
        management?.assignments.removeValue(forKey:id);management?.shortlist.removeAll{$0==id}
        if tactics.captain==id{tactics.captain=nil};tactics.takers=tactics.takers?.filter{$0.value != id}
    }
}
