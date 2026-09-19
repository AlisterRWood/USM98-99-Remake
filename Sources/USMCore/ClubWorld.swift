import Foundation
public struct BoardEvaluation:Codable,Identifiable {
    public var id:Int {period}
    public var period:Int,chairman:Int,finances:Int,fans:Int,dressingRoom:Int
}
public struct PrivateCall:Codable,Identifiable {
    public var id=UUID().uuidString
    public var kind:String,target:String,reply:String
    public var amount:Int,due:Int,resolved=false
}
public struct ClubWorld:Codable {
    public var evaluations:[BoardEvaluation]=[]
    public var calls:[PrivateCall]=[]
    public var readMessages:[String]=[]
    public var scrapbook:[String]=[]
    public var mode="Manager"
    public var dismissed=false
    public init(){}
}
public extension Career {
    var worldState:ClubWorld {world ?? ClubWorld()}
    mutating func initializeWorld(){if world==nil {world=ClubWorld()}}
    @discardableResult mutating func privateCall(kind:String,target:String,amount:Int)->Bool {
        initializeWorld();guard ["Match approach","Transfer bung","Bookmaker"].contains(kind),amount>0,cash>=amount,clubs.contains(where:{$0.id==target && $0.id != clubID}) else{return false}
        if kind != "Transfer bung" {guard let fixture=nextFixture,fixture.round==week,(fixture.home==target || fixture.away==target),!world!.calls.contains(where:{!$0.resolved && $0.kind==kind}) else{return false}}
        transact("Private account",-amount)
        var call=PrivateCall(kind:kind,target:target,reply:"Waiting for a private response",amount:amount,due:managementState.elapsed+1)
        if kind=="Match approach" {
            call.resolved=true
            if rng.unit()<0.3 {transact("Disciplinary fine",-amount*3);confidence=max(0,confidence-30);call.reply="The approach was reported. You have been fined and the board is furious."}
            else if rng.unit()<min(0.5,Double(amount)/300000) {call.reply="Accepted: a contact promises reduced commitment at the next match. No result is guaranteed."}
            else{call.reply="The approach was refused."}
        }
        world!.calls.append(call);return true
    }
    mutating func progressClubWorld(){
        initializeWorld();let now=managementState.elapsed
        if world!.mode=="Coach" {
            initializeManagement()
            if !management!.deals.contains(where:{$0.kind=="Club sponsor" && $0.accepted}) {if let deal=management!.deals.filter({$0.kind=="Club sponsor"}).max(by:{$0.weekly<$1.weekly}) {_=acceptDeal(deal.id)}}
            if cash<500000 {_=bankBorrow(500000)}
            if cash>5_000_000,now%12==0,let stand=groundBuildings.first(where:{$0.kind=="Stand" && !$0.isBuilding}) {_=upgradeBuilding(stand.id)}
        }
        let position=(table().firstIndex{$0.id==clubID} ?? 0)+1
        let financial=max(0,min(100,50+cash/200000-debt/200000))
        let fan=max(0,min(100,100-position*100/max(1,table().count)))
        let morale=squad.reduce(0){$0+(states[$1.id]?.morale ?? 50)}/max(1,squad.count)
        world!.evaluations.append(BoardEvaluation(period:now,chairman:confidence,finances:financial,fans:fan,dressingRoom:morale))
        if world!.evaluations.count>156 {world!.evaluations.removeFirst()}
        for i in world!.calls.indices where !world!.calls[i].resolved && world!.calls[i].due<=now {
            let call=world!.calls[i];var reply=""
            if call.kind=="Bookmaker" {
                let won=lastMatch.map{($0.home==clubID ? $0.homeGoals>$0.awayGoals:$0.awayGoals>$0.homeGoals)} ?? false
                if won {transact("Private winnings",call.amount*2);reply="Your match-win wager paid out."}else{reply="Your wager lost."}
            }else if rng.unit()<0.3 {
                let fine=call.amount*3;transact("Disciplinary fine",-fine);confidence=max(0,confidence-30);reply="The approach was reported. A fine and a severe loss of board confidence follow."
            }else if rng.unit()<min(0.5,Double(call.amount)/300000) {
                reply=call.kind=="Match approach" ? "Accepted: a contact promises reduced opposition commitment for the next meeting. The result is still decided on the pitch.":"Accepted: the intermediary promises a reduced asking price for an enquiry during the next three weeks."
            }else{reply="The recipient rejected the approach. There is no agreement."}
            world!.calls[i].resolved=true;world!.calls[i].reply=reply;post("PRIVATE",call.kind,reply)
        }
        if confidence==0 {world!.dismissed=true;post("BOARD","The board has dismissed you","Choose a new job from the manager’s office.")}
    }
    @discardableResult mutating func applyForJob(_ id:String)->Bool {
        initializeWorld();guard let newClub=clubs.first(where:{$0.id==id}),id != clubID else{return false}
        guard world!.dismissed || newClub.division>=club.division else{return false}
        clubID=id;confidence=55;world!.dismissed=false;ground=nil;capacity=30000;initializeGround();management=nil;cash=2_000_000;debt=0;offers=[];construction=nil;activeMatch=nil;autoSelect();post("CAREER","Appointed at \(newClub.name)","Your new board expects a top-half finish.");return true
    }
}

public extension Career {
    func hasPrivateAgreement(_ kind:String,club:String)->Bool {worldState.calls.contains{$0.kind==kind && $0.target==club && $0.resolved && $0.reply.hasPrefix("Accepted:") && managementState.elapsed<=$0.due+3}}
    func askingPrice(_ player:Player,loan:Bool=false)->Int {let base=loan ? player.value/20:player.value;return hasPrivateAgreement("Transfer bung",club:player.clubID) ? base*90/100:base}
}
