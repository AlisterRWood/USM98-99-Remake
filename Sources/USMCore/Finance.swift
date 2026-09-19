import Foundation
public struct FinanceState:Codable {
    public var overdraftLimit=0
    public var publicCompany=false
    public var grantAmount=0
    public var grantDue:Int?
    public var grantSpent=0
    public var seasonTicketSeason:Int?
    public var seasonTickets=0
    public init(){}
}
public extension Career {
    var financeState:FinanceState {finance ?? FinanceState()}
    mutating func initializeFinance(){if finance==nil{finance=FinanceState()}}
    @discardableResult mutating func arrangeOverdraft()->Bool {initializeFinance();guard confidence>=40,finance!.overdraftLimit==0 else{return false};finance!.overdraftLimit=capacity*10;post("BUSINESS","Overdraft approved","Your bank permits a temporary negative balance up to £\(finance!.overdraftLimit.formatted()). Interest is charged on the amount used.");return true}
    @discardableResult mutating func floatCompany()->Bool {initializeFinance();guard !finance!.publicCompany,confidence>=65,capacity>=20000 else{return false};finance!.publicCompany=true;transact("Share flotation",capacity*100);return true}
    @discardableResult mutating func applyForGrant()->Bool {
        initializeFinance();guard capacity<25000,cash<2_000_000,finance!.grantAmount==0,groundBuildings.contains(where:{$0.kind=="Stand" && $0.specification?.seated==false}) else{return false}
        finance!.grantAmount=500000;finance!.grantDue=managementState.elapsed+12;transact("Football trust grant",500000);post("BOARD","Ground grant awarded","Spend at least £500,000 on ground development within 12 periods. Failure breaches the grant conditions.");return true
    }
    mutating func progressFinance(){
        initializeFinance()
        if cash<0 && finance!.overdraftLimit>0 {transact("Overdraft interest",-abs(cash)/200)}
        if finance!.publicCompany {let profit=ledger.filter{$0.week==(accountingWeek ?? week) && !["loan","Loan","Signed","Sold","flotation","grant","Deposit","Withdrawal"].contains(where:$0.description.contains)}.reduce(0){$0+$1.amount};if profit>0{transact("Shareholder distribution",-profit/20)}}
        if let due=finance!.grantDue,due<=managementState.elapsed {
            if finance!.grantSpent<finance!.grantAmount {confidence=0;initializeWorld();world!.dismissed=true;post("BOARD","Grant conditions breached","The stadium grant was not used as promised. The board has dismissed you.")}
            finance!.grantDue=nil
        }
    }
    var effectiveTicketPrice:Int {
        let tickets=managementState.tickets
        let stands=groundBuildings.filter{$0.kind=="Stand" && !$0.isBuilding}
        let seats=stands.filter{$0.specification?.seated != false}.reduce(0){$0+$1.capacity}
        let terraces=stands.filter{$0.specification?.seated==false}.reduce(0){$0+$1.capacity}
        return (seats*(tickets["Seats"] ?? ticketPrice)+terraces*(tickets["Terrace"] ?? 12))/max(1,seats+terraces)
    }
    mutating func collectGate(_ report:MatchReport,fixture:Fixture){
        initializeFinance();initializeManagement()
        let prices=management!.tickets
        if fixture.competition==nil && finance!.seasonTicketSeason != season {
            finance!.seasonTicketSeason=season
            finance!.seasonTickets=Int(Double(availableCapacity)*max(0.02,0.35-Double(prices["Season"] ?? 300)/2000))
            transact("Season ticket sales",finance!.seasonTickets*(prices["Season"] ?? 300))
        }
        let holders=fixture.competition==nil ? finance!.seasonTickets:0
        let paid=max(0,report.attendance-holders),school=paid/20
        let price=fixture.competition==nil ? effectiveTicketPrice:(prices[fixture.competition=="Friendly" ? "Friendly":"Cup"] ?? ticketPrice)
        let boxes=groundBuildings.filter{!$0.isBuilding}.reduce(0){$0+($1.specification?.boxes ?? 0)}*8
        let executive=min(paid-school,boxes)
        transact("Matchday tickets",max(0,paid-school-executive)*price+school*(prices["School"] ?? 5)+executive*(prices["Executive"] ?? 55))
    }
}
