import SwiftUI
import USMCore
struct TacticsPlayerOption:Hashable {
    var id:String
    var label:String
}
struct TacticsPlayerChoice:View {
    var title:String
    var takerKey:String?
    var players:[TacticsPlayerOption]
    @Binding var tactics:Tactics
    var onChange:()->Void={}
    var body:some View {
        VStack(spacing:2) {
            Text(title).font(.caption).foregroundStyle(mint)
            GameChoice(label:"",value:Binding(get:{
                let id=takerKey == nil ? tactics.captain:tactics.takers?[takerKey!]
                return players.first{$0.id==id}?.label ?? "Any"
            },set:{label in
                let id=players.first{$0.label==label}?.id
                if let takerKey {
                    if tactics.takers == nil {tactics.takers=[:]}
                    tactics.takers?[takerKey]=id
                } else {tactics.captain=id}
                onChange()
            }),options:["Any"]+players.map(\.label))
        }
    }
}
struct TeamTalkScreen:View {
    @EnvironmentObject var store:GameStore
    var body:some View {
        ClassicScreen(title:"Team Talk") {
            HStack(spacing:18) {
                TacticalPitch(lineup:store.career.lineup.compactMap{id in store.career.players.first{$0.id==id}},formation:store.career.tactics.formation).aspectRatio(0.72,contentMode:.fit).frame(maxWidth:400,maxHeight:.infinity)
                VStack(spacing:8) {
                    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:6) {
                        GameChoice(label:"",value:$store.career.tactics.formation,options:["4-4-2","4-3-3","3-5-2","5-3-2"])
                        GameChoice(label:"",value:$store.career.tactics.mentality,options:["Defensive","Balanced","Attacking"])
                        GameChoice(label:"",value:$store.career.tactics.passing,options:["Short","Mixed","Direct"])
                        GameChoice(label:"",value:$store.career.tactics.tackling,options:["Cautious","Normal","Hard"])
                        playerChoice("Captain")
                        Button((store.career.tactics.offsideTrap ?? false) ? "Offside trap: ON":"Offside trap: OFF") {store.career.tactics.offsideTrap = !(store.career.tactics.offsideTrap ?? false);store.save()}
                        ForEach(["Defensive free kick","Attacking free kick","Corner","Penalty"],id:\.self) {playerChoice($0)}
                    }
                    GameNumber(label:"Win bonus £",value:Binding(get:{store.career.tactics.winBonus ?? 0},set:{store.career.tactics.winBonus=$0;store.save()}),range:0...10000,step:100)
                    HStack {Button("Formation editor") {store.page="Formation editor"};Button("Advanced tactics") {store.page="Advanced tactics"}}
                    Spacer(minLength:0)
                    HStack {Button("Team selection") {store.save();store.page="Squad"};Button("Start match") {store.save();store.advance()}}
                }.frame(maxWidth:.infinity)
            }
        }.onDisappear {store.save()}
    }
    func playerChoice(_ title:String)->some View {
        let players=store.career.lineup.enumerated().compactMap { index,id in
            store.career.players.first{$0.id==id}.map {TacticsPlayerOption(id:$0.id,label:"\($0.name) · \(index+1)")}
        }
        return TacticsPlayerChoice(title:title,takerKey:title=="Captain" ? nil:title,players:players,tactics:$store.career.tactics,onChange:store.save)
    }
}
struct FormationEditorScreen:View {
    @EnvironmentObject var store:GameStore
    var advanced=false
    @ViewState var formationName=""
    @ViewState var savedName=""
    @ViewState var notice=""
    @ViewState var situation="Attack zone 1"
    @ViewState var selected=0
    @ViewState var clipboard:[TacticalInstruction]?
    @ViewState var undo:[TacticalInstruction]?
    var instructions:[TacticalInstruction] {if advanced{return store.career.tactics.plan?.states[situation] ?? TacticalPlan.defaults(store.career.tactics)};return (store.career.tactics.customPositions ?? TacticalPlan.defaults(store.career.tactics).map(\.point)).map{TacticalInstruction(point:$0)}}
    var body:some View {
        ClassicScreen(title:advanced ? "Advanced Tactics":"Formation Editor") {
            HStack {
                TextField("Formation name",text:$formationName).textFieldStyle(.plain).padding(7).background(.black.opacity(0.3)).frame(width:170)
                Button("Save formation") {if store.career.saveFormation(named:formationName){savedName=formationName.trimmingCharacters(in:.whitespacesAndNewlines);notice="Saved "+savedName;store.save()}}.disabled(formationName.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                GameChoice(label:"Saved",value:$savedName,options:store.career.managementState.savedFormations?.map(\.name) ?? [])
                Button("Load") {if store.career.loadFormation(named:savedName){formationName=savedName;notice="Loaded "+savedName;undo=nil;store.save()}}.disabled(savedName.isEmpty)
                Button("Delete") {store.career.deleteFormation(named:savedName);savedName="";notice="Formation deleted";store.save()}.disabled(savedName.isEmpty)
            }
            if !notice.isEmpty {Text(notice).font(.caption).foregroundStyle(mint)}
            if advanced {GameChoice(label:"Situation",value:$situation,options:TacticalPlan.situations)}
            HStack {
                GeometryReader {geo in
                    ZStack {PitchLines();ForEach(0..<11,id:\.self) {slot in
                        let point=instructions[slot].point
                        Text("\(slot+1)").bold().frame(width:29,height:29).background(slot==selected ? crimson:royal,in:Circle()).overlay(Circle().stroke(.white)).position(x:point.y/68*geo.size.width,y:(1-point.x/105)*geo.size.height)
                            .gesture(DragGesture(minimumDistance:0).onChanged{value in selected=slot;var list=instructions;list[slot].point=FieldPoint(max(1,min(104,(1-value.location.y/geo.size.height)*105)),max(1,min(67,value.location.x/geo.size.width*68)));save(list)})
                    }}
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
                VStack(alignment:.leading,spacing:4) {
                    Text("Drag the shirt to set its position.").foregroundStyle(mint)
                    ForEach(Array(store.career.lineup.enumerated()),id:\.offset) {i,id in Button("\(i+1)  "+(store.career.players.first{$0.id==id}?.name ?? "Player")) {selected=i}.buttonStyle(GameButton(red:selected==i))}
                    if advanced {
                        Text("Selected player instruction").font(.caption).foregroundStyle(mint)
                        GameChoice(label:"Action",value:Binding(get:{instructions.indices.contains(selected) ? instructions[selected].action:"Move"},set:{value in var list=instructions;if list.indices.contains(selected){list[selected].action=value;save(list)}}),options:["Move","Pass","Dribble","Wait","Shoot"])
                        if instructions.indices.contains(selected) && instructions[selected].action == "Pass" {
                            let playerNames=store.career.lineup.map { id in store.career.players.first(where:{ $0.id == id })?.name ?? "Player" }
                            GameChoice(label:"Target",value:Binding(get:{let target=instructions[selected].targetSlot;return target >= 0 && target < playerNames.count ? playerNames[target]:"Any"},set:{value in var list=instructions;if list.indices.contains(selected){list[selected].targetSlot=playerNames.firstIndex(of:value) ?? -1;save(list)}}),options:["Any"]+playerNames)
                        }
                    }
                    Spacer(minLength:0)
                    HStack {Button("Copy") {clipboard=instructions};Button("Paste") {if let clipboard {undo=instructions;save(clipboard)}}.disabled(clipboard==nil)}
                    HStack {Button("Reset") {undo=instructions;if advanced {save(TacticalPlan.defaults(store.career.tactics))}else{store.career.tactics.customPositions=nil;store.save()}};Button("Undo") {if let undo {save(undo);self.undo=nil}}.disabled(undo==nil)}
                }.frame(width:250)
            }
        }
    }
    func save(_ list:[TacticalInstruction]) {if advanced {if store.career.tactics.plan==nil {store.career.tactics.plan=TacticalPlan()};store.career.tactics.plan?.states[situation]=list}else{store.career.tactics.customPositions=list.map(\.point)};store.save()}
}
