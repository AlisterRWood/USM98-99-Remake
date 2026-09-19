import SwiftUI
import SceneKit
import USMCore

struct GroundManagementView:View {
    @EnvironmentObject var store:GameStore
    @ViewState var editing=false
    @ViewState var selectedID:String?
    @ViewState var selectedPlot:String?
    @ViewState var hovered:String?
    @ViewState var kind="Shop"
    @ViewState var movingID:String?
    @ViewState var status="Click a building to enter. Scroll or pinch to zoom."
    @ViewState var confirmDemolition=false
    @ViewState var standEditor=false
    @ViewState var facilityEditor=false
    var selected:GroundBuilding? {store.career.groundBuildings.first{$0.id==selectedID}}
    var body:some View {
        VStack(spacing:0) {
            HStack(spacing:0) {
                GroundSceneView(buildings:store.career.groundBuildings,showPlots:editing,selected:selectedID.map{"building:\($0)"},onPick:pick,onHover:{hovered=$0})
                    .overlay(alignment:.bottomLeading) {Text("LIVE 3D GROUND · SCROLL OR PINCH TO ZOOM").font(.system(size:8,weight:.bold,design:.monospaced)).tracking(1).padding(10).background(.black.opacity(0.55),in:Capsule()).padding(16)}
            }
            HStack(spacing:20) {
                VStack(alignment:.leading,spacing:4) {Text(store.career.club.stadium).font(.system(size:21,weight:.bold,design:.serif));Text("\(store.career.capacity.formatted()) SEATS · \(store.career.groundBuildings.filter{$0.isBuilding}.count) PROJECTS UNDERWAY").font(.system(size:9,weight:.bold)).tracking(1).foregroundStyle(muted)}
                Spacer()
                GameChoice(label:"",value:Binding(get:{selected?.title ?? "Facilities"},set:{value in if let b=store.career.groundBuildings.first(where:{$0.title==value}) {pick("building:\(b.id)")}}),options:["Facilities"]+store.career.groundBuildings.map(\.title)).frame(width:240)
                if editing {Button("Plan a facility") {selectedID=nil;selectedPlot=nil;facilityEditor=true}.buttonStyle(AccentButton())}
                Button(editing ? "Finish construction planning":"Develop the ground") {editing.toggle();selectedPlot=nil;movingID=nil;status=editing ? "Select a facility to improve it, or choose a vacant plot.":"Click a building to enter."}.buttonStyle(AccentButton())
            }.padding(.horizontal,24).padding(.vertical,14).background(panel)
        }
        .sheet(isPresented:$standEditor) {if let b=selected {StandEditor(building:b).classicSheet("Stand Development")}}
        .sheet(isPresented:$facilityEditor) {editor.frame(width:430,height:580).background(panel).disabled(store.career.worldState.mode=="Coach").classicSheet("Facility Development")}
        .onAppear {store.career.initializeGround();editing=store.page=="Stadium development"}
        .overlay {
            if confirmDemolition {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ClassicDialog(title:"Demolish this facility?") {
                        Text("The facility’s capacity or income will be removed. You receive 10% of the base construction cost in salvage.").padding(12)
                        HStack {
                            Button("Cancel") {confirmDemolition=false}.keyboardShortcut(.cancelAction)
                            Button("Demolish") {
                                if let b=selected,store.career.demolishBuilding(b.id) {status="\(b.title) removed. Its plot is available again.";selectedID=nil;store.save();store.audio.play("st_buildings")}
                                confirmDemolition=false
                            }
                        }.frame(maxWidth:.infinity).padding(8).classicRibbon()
                    }.frame(width:560)
                }
            }
        }
    }
    var hoverText:String {
        if let hovered=hovered {
            if hovered=="pitch" {return "The pitch · Enter the dressing room"}
            if hovered.hasPrefix("plot:") {return "Vacant plot · \(movingID==nil ? "Select a site for your new facility":"Click to move the selected building here")"}
            if let b=store.career.groundBuildings.first(where:{"building:\($0.id)"==hovered}) {return "\(b.title) · \(b.isBuilding ? "Under construction; \(max(0,(b.dueWeek ?? 0)-store.career.week)) weeks remaining":(editing ? "Click to manage":"Click to enter"))"}
        }
        return status
    }
    func pick(_ id:String) {
        if id=="pitch" {if !editing {store.enter("Dressing room")};return}
        if id.hasPrefix("plot:") {
            let plot=String(id.dropFirst(5))
            if let moving=movingID {
                if store.career.moveBuilding(moving,to:plot) {status="Facility relocated. Layout saved.";movingID=nil;store.save();store.audio.play("st_buildings")}
                else {status="Choose an empty perimeter plot for this building."}
            } else {selectedPlot=plot;selectedID=nil;status="Plot selected. Choose a facility and commission construction."}
            return
        }
        guard let b=store.career.groundBuildings.first(where:{"building:\($0.id)"==id}) else {return}
        if b.kind=="Stand" && !b.isBuilding {
            selectedID=b.id;selectedPlot=nil;movingID=nil;standEditor=true;return
        }
        if editing || b.isBuilding {editing=true;selectedID=b.id;selectedPlot=nil;movingID=nil;facilityEditor=true;return}
        if ["Manager’s office","Boardroom","Dressing room","Business office","Transfer office"].contains(b.kind) {store.enter(b.destination)}
        else {store.navigate(b.destination,sound:b.kind=="Training" ? "sq_teamtraining":"bs_merchandise")}
    }
    var editor:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("GROUND DEVELOPMENT").font(.system(size:10,weight:.black)).tracking(1.5).foregroundStyle(mint)
            if let b=selected {
                Text(b.title).font(.system(size:24,weight:.bold,design:.serif))
                Text("Level \(b.level) · \(b.plotID)").font(.system(size:11)).foregroundStyle(muted)
                if b.kind=="Stand" {Text("\(b.capacity.formatted()) seats").font(.system(size:22,weight:.semibold))}
                if b.isBuilding {
                    Label("Under construction",systemImage:"hammer").foregroundStyle(mint)
                    Text("\(max(0,(b.dueWeek ?? 0)-store.career.week)) weeks until completion. Scaffolding marks the work site on your ground.").font(.system(size:12)).foregroundStyle(muted)
                } else {
                    if b.kind=="Stand" {Button("View / improve stand") {standEditor=true}.buttonStyle(AccentButton())}
                    if GroundRules.buildable.contains(b.kind) && b.kind != "Stand" {
                        let cost=GroundRules.cost(b.kind,level:b.level)
                        Text(b.kind=="Stand" ? "Add 5,000 seats and a larger stand.":"Expand this facility’s contribution to the club.").font(.system(size:12)).foregroundStyle(muted)
                        Button("Upgrade · \(money(cost))") {if store.career.upgradeBuilding(b.id) {store.save();store.audio.play("st_buildings");status="Expansion commissioned."}}.buttonStyle(AccentButton()).disabled(store.career.cash<cost)
                        Text("\(GroundRules.weeks(b.kind)) weeks to complete").font(.system(size:10)).foregroundStyle(muted)
                    }
                    if b.kind != "Stand" {
                        Button(movingID==b.id ? "Choose an empty plot…":"Move building") {movingID=b.id;status="Click an empty yellow plot to relocate \(b.title)."}
                        Button("Rotate 90°") {store.career.rotateBuilding(b.id);store.save()}
                    }
                    if GroundRules.buildable.contains(b.kind) && b.kind != "Stand" {Button("Demolish…",role:.destructive) {confirmDemolition=true}.foregroundStyle(.orange)}
                }
                Divider()
                Button("Plan a new facility") {selectedID=nil;selectedPlot=nil;movingID=nil}
            } else {
                Text("Make room for ambition.").font(.system(size:24,weight:.bold,design:.serif))
                GameChoice(label:"Build",value:$kind,options:GroundRules.buildable)
                Text(kind=="Stand" ? "A new stand adds 5,000 seats. Select an empty stand position by the pitch.":"Choose any empty yellow plot around the ground. Buildings can be moved and rotated after completion.").font(.system(size:12)).foregroundStyle(muted)
                Text(money(GroundRules.cost(kind))).font(.system(size:28,weight:.bold,design:.rounded)).foregroundStyle(mint)
                Text("\(GroundRules.weeks(kind)) weeks construction").font(.system(size:12)).foregroundStyle(muted)
                if let plot=selectedPlot {Text("Selected: \(plot)").font(.system(size:11,weight:.bold));let valid=GroundPlot.all.first{$0.id==plot}?.stand==(kind=="Stand")
                    if !valid {Text(kind=="Stand" ? "Stands must occupy a stand position.":"Facilities need a perimeter plot.").font(.system(size:11)).foregroundStyle(.orange)}
                    Button("Commission construction") {if store.career.placeBuilding(kind:kind,plotID:plot) {store.save();store.audio.play("st_buildings");selectedID=store.career.groundBuildings.first{$0.plotID==plot}?.id;selectedPlot=nil;status="Construction has begun."}}.buttonStyle(AccentButton()).disabled(!valid || store.career.cash<GroundRules.cost(kind))
                } else {Label("Select a plot on the ground",systemImage:"cursorarrow").font(.system(size:12)).foregroundStyle(mint)}
                // Also accessible without a pointing device or 3D hit testing.
                GameChoice(label:"",value:Binding(get:{selectedPlot ?? "Choose a plot"},set:{selectedPlot=$0=="Choose a plot" ? nil:$0}),options:["Choose a plot"]+GroundPlot.all.filter{plot in plot.stand==(kind=="Stand") && !store.career.groundBuildings.contains{$0.plotID==plot.id}}.map(\.id))
            }
            Spacer(minLength:25)
        }.padding(14)
    }
}

struct StandEditor:View {
    @EnvironmentObject var store:GameStore
    @Environment(\.dismiss) var dismiss
    var building:GroundBuilding
    @ViewState var capacity=0
    @ViewState var seating="Seats"
    @ViewState var roof="Covered"
    @ViewState var boxes=0
    var quote:Int? {store.career.standQuote(building.id,capacity:capacity,seated:seating=="Seats",covered:roof=="Covered",boxes:boxes)}
    var draft:GroundBuilding {var value=building;value.capacity=capacity;var spec=value.specification ?? StandSpecification();spec.seated=seating=="Seats";spec.covered=roof=="Covered";spec.boxes=boxes;value.specification=spec;return value}
    var body:some View {
        VStack(spacing:12) {
            Text("Improve Stadium · "+building.title).font(.title.bold()).foregroundStyle(mint)
            HStack(spacing:18) {
                VStack(spacing:14) {
                    GameNumber(label:"Capacity",value:$capacity,range:building.capacity...40000,step:1000)
                    GameChoice(label:"Accommodation",value:$seating,options:(building.specification?.seated ?? true) ? ["Seats"]:["Terrace","Seats"])
                    GameChoice(label:"Roof",value:$roof,options:["Open","Covered"])
                    GameNumber(label:"Executive boxes",value:$boxes,range:(building.specification?.boxes ?? 0)...50).disabled(building.plotID.contains("-"))
                    Text("Improvement cost: "+(quote.map{money($0)} ?? "No changes"))
                    Text("Cash available: "+money(store.career.cash))
                    Text("Construction: \(quote==nil ? 0:max(2,(capacity-building.capacity)/2000+2)) weeks")
                }.frame(width:310)
                VStack {StandPreview(building:draft).frame(maxWidth:.infinity,maxHeight:.infinity);Text(StandAppearance(capacity:capacity).label+" · \(capacity.formatted()) capacity").foregroundStyle(mint)}
            }.frame(height:315)
            Text("LIVE PROPOSAL · Change capacity and roof to preview your stand before commissioning.").font(.caption).foregroundStyle(mint)
            Text("Condition: \(building.specification?.condition ?? 100)% · Stand closes during construction").foregroundStyle(muted)
            HStack {Button("Cancel") {dismiss()};Button("Maintain") {_=store.career.maintainStand(building.id);store.save();dismiss()};Spacer();Button("Commission · "+(quote.map{money($0)} ?? "No changes")) {if store.career.developStand(building.id,capacity:capacity,seated:seating=="Seats",covered:roof=="Covered",boxes:boxes){store.save();dismiss()}}.disabled(quote==nil || (quote ?? 0)>store.career.cash)}
        }.padding(20).frame(width:820,height:460).background(panel).background(RightClickBack {dismiss()}).buttonStyle(GameButton(red:true)).onAppear {capacity=building.capacity;seating=(building.specification?.seated ?? true) ? "Seats":"Terrace";roof=(building.specification?.covered ?? true) ? "Covered":"Open";boxes=building.specification?.boxes ?? 0}
    }
}

struct StandPreview:NSViewRepresentable {
    var building:GroundBuilding
    class Coordinator {var last:GroundBuilding?}
    func makeCoordinator()->Coordinator{Coordinator()}
    func makeNSView(context:Context)->SCNView {
        let view=SCNView();view.allowsCameraControl=true;view.antialiasingMode = .multisampling4X
        let scene=SCNScene();scene.background.contents=NSColor(calibratedRed:0.12,green:0.12,blue:0.24,alpha:1)
        let group=SCNNode();group.name="stand-preview";scene.rootNode.addChildNode(group);var front=building;front.plotID="south";EstateRenderer.stand(group,front);context.coordinator.last=building
        let light=SCNNode();light.light=SCNLight();light.light!.type = .omni;light.light!.intensity=1500;light.position=SCNVector3(20,70,60);scene.rootNode.addChildNode(light)
        let ambient=SCNNode();ambient.light=SCNLight();ambient.light!.type = .ambient;ambient.light!.intensity=700;scene.rootNode.addChildNode(ambient)
        let camera=SCNNode();camera.camera=SCNCamera();camera.camera!.usesOrthographicProjection=true;camera.camera!.orthographicScale=42;camera.camera!.zFar=1000;camera.camera!.zNear=0.1;camera.position=SCNVector3(65,55,-95);camera.look(at:SCNVector3(0,6,0));scene.rootNode.addChildNode(camera);view.scene=scene;view.pointOfView=camera;return view
    }
    func updateNSView(_ view:SCNView,context:Context){
        guard context.coordinator.last != building,let root=view.scene?.rootNode else{return}
        root.childNode(withName:"stand-preview",recursively:false)?.removeFromParentNode()
        let group=SCNNode();group.name="stand-preview";root.addChildNode(group);var front=building;front.plotID="south";EstateRenderer.stand(group,front);context.coordinator.last=building
    }
}
