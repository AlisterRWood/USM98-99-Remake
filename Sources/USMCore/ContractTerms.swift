import Foundation
public struct ContractBonuses:Codable {
    public var league=0,cup=0,promotion=0,final=0,win=0,goal=0
    public init(){}
}
public struct TransferObligation:Codable,Identifiable {
    public var id=UUID().uuidString
    public var playerID:String,creditor:String
    public var appearances:Int,threshold:Int,fee:Int,paid=false
}
public extension Career {
    mutating func updateTransferExtras(_ id:String,appearanceFee:Int,appearanceCount:Int,swap:String?,bonuses:ContractBonuses){
        initializeManagement();guard let i=management!.negotiations.firstIndex(where:{$0.id==id && ["Club asking price","Club counter offer","Player terms","Player counter offer"].contains($0.stage)}),management!.negotiations[i].expires >= management!.elapsed,let player=players.first(where:{$0.id==management!.negotiations[i].playerID}),management!.negotiations[i].selling ? player.clubID==clubID:player.clubID==management!.negotiations[i].clubID,appearanceFee>=0,(1...100).contains(appearanceCount),[bonuses.league,bonuses.cup,bonuses.promotion,bonuses.final,bonuses.win,bonuses.goal].allSatisfy({$0>=0}),swap==nil || canRelease(swap!) else{return}
        if management!.negotiations[i].stage.hasPrefix("Club") {management!.negotiations[i].appearanceFee=appearanceFee;management!.negotiations[i].appearanceCount=appearanceCount;management!.negotiations[i].swapPlayer=swap};management!.negotiations[i].bonuses=bonuses
    }
    mutating func payAppearanceAndMatchBonuses(_ match:LiveMatch){
        initializeManagement();let used=match.players.filter{$0.side==match.managedSide && ($0.onPitch || $0.used)}.map(\.id)
        let won=match.managedSide==0 ? match.homeGoals>match.awayGoals:match.awayGoals>match.homeGoals
        for id in used {
            if let terms=management!.playerBonuses?[id] {
                let goals=match.events.filter{$0.kind=="goal" && $0.playerID==id}.count
                let amount=(won ? terms.win:0)+goals*terms.goal
                if amount>0 {transact("Player performance bonus",-amount)}
            }
        }
        if management!.obligations != nil {
            for i in management!.obligations!.indices where !management!.obligations![i].paid && used.contains(management!.obligations![i].playerID) {
                management!.obligations![i].appearances+=1
                let o=management!.obligations![i]
                if o.appearances>=o.threshold {transact("Transfer appearance instalment",-o.fee);management!.obligations![i].paid=true;post("TRANSFER","Appearance clause due","An agreed instalment of £\(o.fee.formatted()) has been paid to \(name(o.creditor)).")}
            }
        }
    }
}

public extension Career {
    @discardableResult mutating func enquireRenewal(_ id:String)->Bool {
        initializeManagement();guard let p=squad.first(where:{$0.id==id}),!management!.negotiations.contains(where:{$0.playerID==id && !$0.closed}) else{return false}
        var n=Negotiation(player:p,week:management!.elapsed);n.fee=0;n.stage="Player terms";n.reply="Discuss a new contract with your player. Agree wages, signing fee, term and bonuses, then give final approval.";management!.negotiations.append(n);return true
    }
}
