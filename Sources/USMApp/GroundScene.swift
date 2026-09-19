import SwiftUI
import SceneKit
import USMCore

final class EstateSCNView:SCNView {
    var onPick:((String)->Void)?
    var onHoverItem:((String?)->Void)?
    private var downPoint=NSPoint.zero
    private var tracking:NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking=tracking {removeTrackingArea(tracking)}
        tracking=NSTrackingArea(rect:bounds,options:[.mouseMoved,.mouseEnteredAndExited,.activeAlways,.inVisibleRect],owner:self,userInfo:nil)
        addTrackingArea(tracking!)
    }
    func item(at point:NSPoint)->String? {
        for hit in hitTest(point,options:[.searchMode:SCNHitTestSearchMode.all.rawValue]) {
            var node:SCNNode?=hit.node
            while let n=node {
                if let name=n.name,name.hasPrefix("building:") || name.hasPrefix("plot:") || name=="pitch" {return name}
                node=n.parent
            }
        }
        return nil
    }
    override func mouseMoved(with event:NSEvent) {
        let id=item(at:convert(event.locationInWindow,from:nil));onHoverItem?(id)
        if id != nil {NSCursor.pointingHand.set()} else {NSCursor.arrow.set()}
        super.mouseMoved(with:event)
    }
    override func mouseExited(with event:NSEvent) {onHoverItem?(nil);NSCursor.arrow.set()}
    override func mouseDown(with event:NSEvent) {downPoint=convert(event.locationInWindow,from:nil);super.mouseDown(with:event)}
    // The ground has a fixed isometric viewpoint. Dragging is deliberately a
    // no-op so a click cannot accidentally orbit the stadium away from it.
    override func mouseDragged(with event:NSEvent) {}
    override func scrollWheel(with event:NSEvent){zoom(Double(event.scrollingDeltaY)*0.7)}
    override func magnify(with event:NSEvent){zoom(-Double(event.magnification)*100)}
    private func zoom(_ delta:Double){guard let camera=pointOfView?.camera else{return};camera.orthographicScale=max(65,min(135,camera.orthographicScale+delta))}
    override func mouseUp(with event:NSEvent) {
        let point=convert(event.locationInWindow,from:nil)
        if hypot(point.x-downPoint.x,point.y-downPoint.y)<5,let id=item(at:point) {onPick?(id)}
        super.mouseUp(with:event)
    }
}
struct GroundSceneView:NSViewRepresentable {
    var buildings:[GroundBuilding]
    var showPlots:Bool
    var selected:String?
    var onPick:(String)->Void
    var onHover:(String?)->Void
    class Coordinator {var buildings:[GroundBuilding]=[];var showPlots=false}
    func makeCoordinator()->Coordinator {Coordinator()}
    func makeNSView(context:Context)->EstateSCNView {
        let view=EstateSCNView();view.backgroundColor=NSColor(calibratedRed:0.11,green:0.19,blue:0.14,alpha:1)
        view.antialiasingMode = .multisampling4X;view.allowsCameraControl=false
        view.defaultCameraController.minimumVerticalAngle=25;view.defaultCameraController.maximumVerticalAngle=80
        view.defaultCameraController.inertiaEnabled=true
        view.scene=EstateRenderer.make(buildings:buildings,showPlots:showPlots)
        context.coordinator.buildings=buildings;context.coordinator.showPlots=showPlots
        view.onPick=onPick;view.onHoverItem=onHover
        return view
    }
    func updateNSView(_ view:EstateSCNView,context:Context) {
        view.onPick=onPick;view.onHoverItem=onHover
        if context.coordinator.buildings != buildings || context.coordinator.showPlots != showPlots {
            let transform=view.pointOfView?.transform
            let scale=view.pointOfView?.camera?.orthographicScale
            view.scene=EstateRenderer.make(buildings:buildings,showPlots:showPlots)
            if let camera=view.scene?.rootNode.childNode(withName:"camera",recursively:true) {
                if let transform=transform {camera.transform=transform};if let scale=scale {camera.camera?.orthographicScale=scale};view.pointOfView=camera
            }
            context.coordinator.buildings=buildings;context.coordinator.showPlots=showPlots
        }
        view.scene?.rootNode.enumerateChildNodes {node,_ in
            if node.name=="selection" {node.isHidden=node.parent?.name != selected}
        }
    }
}
enum EstateRenderer {
    static let grass=NSColor(calibratedRed:0.23,green:0.40,blue:0.16,alpha:1)
    static let brick=NSColor(calibratedRed:0.49,green:0.25,blue:0.15,alpha:1)
    static let roof=NSColor(calibratedRed:0.26,green:0.29,blue:0.30,alpha:1)
    static let cream=NSColor(calibratedRed:0.91,green:0.87,blue:0.72,alpha:1)
    @discardableResult static func box(_ parent:SCNNode,_ w:CGFloat,_ h:CGFloat,_ d:CGFloat,_ x:Float,_ y:Float,_ z:Float,_ color:NSColor,_ bevel:CGFloat=0)->SCNNode {
        let g=SCNBox(width:w,height:h,length:d,chamferRadius:bevel);g.firstMaterial?.diffuse.contents=color;g.firstMaterial?.roughness.contents=0.85
        let n=SCNNode(geometry:g);n.position=SCNVector3(x,y,z);parent.addChildNode(n);return n
    }
    static func make(buildings:[GroundBuilding],showPlots:Bool)->SCNScene {
        let scene=SCNScene();let root=scene.rootNode
        scene.background.contents=NSColor(calibratedRed:0.19,green:0.27,blue:0.21,alpha:1)
        neighbourhood(root)
        _=box(root,322,3,266,0,-2,0,grass,2)
        _=box(root,188,0.1,137,0,0.05,0,NSColor(calibratedWhite:0.43,alpha:1))
        // Perimeter road and internal pedestrian ring.
        let road=NSColor(calibratedWhite:0.26,alpha:1),path=NSColor(calibratedRed:0.64,green:0.61,blue:0.49,alpha:1)
        for z:Float in [-122,122] {_=box(root,314,0.2,11,0,0,z,road)}
        for x:Float in [-151,151] {_=box(root,11,0.2,245,x,0,0,road)}
        for z:Float in [-60,60] {_=box(root,180,0.25,7,0,0.15,z,path)}
        for x:Float in [-85,85] {_=box(root,7,0.25,126,x,0.15,0,path)}
        for z:Float in [-120,120] {for x in stride(from:Float(-140),through:140,by:9) {_=box(root,4,0.1,0.18,x,0.2,z,cream)}}
        // Trees give the club a lived-in setting rather than an isolated model.
        for i in 0..<64 {
            let side=i%4,t=Float(i/4)*18-137
            let x:Float=side==0 ? -145:(side==1 ? 145:t)
            let z:Float=side==2 ? -115:(side==3 ? 115:Float(i/4)*14-107)
            tree(root,x:x,z:z,seed:i)
        }
        for i in 0..<24 {
            let x=Float(i)*10-118
            let color:[NSColor]=[.darkGray,.white,.systemRed,.systemBlue,cream]
            _=box(root,4.5,2,8,x,1,111,color[i%color.count],1)
            _=box(root,3.9,1.3,4.6,x,2.5,111,NSColor(calibratedRed:0.24,green:0.32,blue:0.37,alpha:1),0.5)
        }
        pitch(root)
        for b in buildings {building(root,b)}
        if showPlots {
            let occupied=Set(buildings.map(\.plotID))
            for plot in GroundPlot.all where !occupied.contains(plot.id) {
                let n=box(root,plot.stand ? 18:23,0.18,plot.stand ? 18:23,Float(plot.x),0.7,Float(plot.z),NSColor(calibratedRed:0.91,green:0.77,blue:0.29,alpha:0.55),0.3)
                n.name="plot:\(plot.id)";n.geometry?.firstMaterial?.transparency=0.6
            }
        }
        for x:Float in [-77,77] {for z:Float in [-54,54] {
            for dx:Float in [-0.65,0.65] {_=box(root,0.4,34,0.4,x+dx,17,z,.lightGray)}
            for h in stride(from:Float(4),through:32,by:4) {_=box(root,2.4,0.3,1,x,h,z,.lightGray)}
            _=box(root,8,3,1,x,34,z,cream);for k in 0..<5 {let lamp=box(root,1,1.2,0.25,x-3+Float(k)*1.5,34,z+0.7,.white);lamp.geometry?.firstMaterial?.emission.contents=cream}
        }}
        // Tiny supporters in motion around the concourse, entirely independent of scenery art.
        for i in 0..<32 {
            let x=Float((i*17)%150)-75,z:Float=i%2==0 ? 61:-61
            let person=SCNNode();root.addChildNode(person)
            _=box(person,0.75,1.35,0.6,0,1,0,i%3==0 ? .systemRed:.darkGray,0.2)
            let head=SCNSphere(radius:0.34);head.firstMaterial?.diffuse.contents=NSColor(calibratedRed:0.7,green:0.51,blue:0.33,alpha:1)
            let hn=SCNNode(geometry:head);hn.position=SCNVector3(0,1.95,0);person.addChildNode(hn);person.position=SCNVector3(x,0.3,z)
            person.runAction(.repeatForever(.sequence([.moveBy(x:8,y:0,z:0,duration:9),.moveBy(x:-8,y:0,z:0,duration:9)])))
        }
        let ambient=SCNNode();ambient.light=SCNLight();ambient.light!.type = .ambient;ambient.light!.intensity=650;ambient.light!.color=NSColor(calibratedRed:0.83,green:0.89,blue:1,alpha:1);root.addChildNode(ambient)
        let sun=SCNNode();sun.light=SCNLight();sun.light!.type = .directional;sun.light!.intensity=1700;sun.light!.color=NSColor(calibratedRed:1,green:0.91,blue:0.75,alpha:1);sun.light!.castsShadow=true;sun.light!.shadowRadius=4;sun.light!.shadowMapSize=CGSize(width:2048,height:2048);sun.light!.orthographicScale=230;sun.eulerAngles=SCNVector3(-0.85,-0.5,0);root.addChildNode(sun)
        let camera=SCNNode();camera.name="camera";camera.camera=SCNCamera();camera.camera!.usesOrthographicProjection=true;camera.camera!.orthographicScale=82;camera.camera!.zFar=1500;camera.position=SCNVector3(170,260,330);camera.look(at:SCNVector3(0,0.5,0));root.addChildNode(camera)
        return scene
    }
    static func neighbourhood(_ root:SCNNode) {
        let town=SCNNode();root.addChildNode(town)
        let asphalt=NSColor(calibratedWhite:0.27,alpha:1),paving=NSColor(calibratedWhite:0.49,alpha:1)
        _=box(town,1800,1,1800,0,-3,0,paving)
        // Permanent scenery beyond the editable estate: streets and terraced housing.
        for street in stride(from:-720,through:720,by:90) {
            let t=Float(street)
            if abs(street)>160 {_=box(town,1800,0.2,13,0,-2.3,t,asphalt);_=box(town,13,0.2,1800,t,-2.3,0,asphalt)}
        }
        for row in -7...7 {for col in -7...7 {
            let x=Float(col*90),z=Float(row*90)
            if abs(x)<180 && abs(z)<180 {continue}
            for i in 0..<4 {
                let bx=x+Float(i*16)-25,bz=z+24,h:CGFloat=CGFloat(12+abs(row+col)%3*3)
                _=box(town,14,h,26,bx,Float(h/2)-2,bz,brick)
                _=box(town,15,3,28,bx,Float(h)-1,bz,roof,0.3)
                _=box(town,2,5,2,bx+4,Float(h)+2,bz-4,brick)
                for floor in 0..<2 {for side:Float in [-1,1] {for dx:Float in [-4,4] {
                    _=box(town,3,3,0.2,bx+dx,Float(floor*5+3),bz+side*13.1,cream)
                }}}
                _=box(town,2.5,5,0.3,bx,0.5,bz+13.2,.darkGray)
            }
        }}
        // Static town geometry is flattened for rendering performance.
        var palette:[NSColor:SCNMaterial]=[:]
        town.enumerateChildNodes {node,_ in
            guard let geometry=node.geometry,let color=geometry.firstMaterial?.diffuse.contents as? NSColor else{return}
            if let material=palette[color]{geometry.materials=[material]}else{let material=geometry.firstMaterial!;palette[color]=material}
        }
        let flat=town.flattenedClone();town.removeFromParentNode();root.addChildNode(flat)
    }
    static func tree(_ parent:SCNNode,x:Float,z:Float,seed:Int) {
        _=box(parent,0.7,5,0.7,x,2.5,z,NSColor.brown)
        let sphere=SCNSphere(radius:3.2+Double(seed%3)*0.5);sphere.segmentCount=7;sphere.firstMaterial?.diffuse.contents=NSColor(calibratedRed:0.16+Double(seed%3)*0.025,green:0.32+Double(seed%4)*0.03,blue:0.09,alpha:1)
        let crown=SCNNode(geometry:sphere);crown.position=SCNVector3(x,6,z);crown.scale=SCNVector3(1,1.3,1);parent.addChildNode(crown)
    }
    static func pitch(_ root:SCNNode) {
        let node=SCNNode();node.name="pitch";root.addChildNode(node)
        for i in 0..<14 {_=box(node,7.5,0.15,68,-48.75+Float(i)*7.5,0.2,0,NSColor(calibratedRed:0.15,green:i%2==0 ? 0.43:0.48,blue:0.18,alpha:1))}
        for z:Float in [-34,34] {_=box(node,105,0.07,0.18,0,0.31,z,.white)}
        for x:Float in [-52.5,0,52.5] {_=box(node,0.18,0.07,68,x,0.31,0,.white)}
        let torus=SCNTorus(ringRadius:9.15,pipeRadius:0.09);torus.firstMaterial?.diffuse.contents=NSColor.white
        let circle=SCNNode(geometry:torus);circle.position=SCNVector3(0,0.35,0);node.addChildNode(circle)
        for sign:Float in [-1,1] {
            _=box(node,0.18,0.07,40.3,sign*36,0.32,0,.white)
            for z:Float in [-20.15,20.15] {_=box(node,16.5,0.07,0.18,sign*44.25,0.32,z,.white)}
            for z:Float in [-3.66,3.66] {_=box(node,0.17,2.44,0.17,sign*52.5,1.3,z,.white)}
            _=box(node,0.17,0.17,7.5,sign*52.5,2.5,0,.white)
            let net=box(node,2,2.4,7.3,sign*53.5,1.3,0,NSColor.white.withAlphaComponent(0.25));net.geometry?.firstMaterial?.transparency=0.2
        }
    }
    static func building(_ root:SCNNode,_ b:GroundBuilding) {
        let group=SCNNode();group.name="building:\(b.id)";group.position=SCNVector3(b.plot.x,0,b.plot.z);group.eulerAngles.y=CGFloat(b.rotation)*CGFloat.pi/2;root.addChildNode(group)
        let selection=box(group,b.kind=="Stand" ? 24:25,0.15,b.kind=="Stand" ? 24:25,0,0.3,0,NSColor.systemYellow.withAlphaComponent(0.6),1);selection.name="selection";selection.isHidden=true
        if b.kind=="Stand" {stand(group,b)}
        else if b.kind=="Car park" {
            _=box(group,25,0.2,24,0,0.2,0,.darkGray)
            for i in 0..<8 {let x=Float(i%4)*5-8,z=Float(i/4)*12-6;_=box(group,3.5,1.6,7,x,1,z,i%2==0 ? .white:.systemRed,0.5);_=box(group,0.15,0.1,9,x-2,0.4,z,.white)}
        }else if b.kind=="Training" {
            _=box(group,24,0.3,22,0,0.3,0,grass)
            for z:Float in [-9,9] {_=box(group,21,0.08,0.12,0,0.5,z,.white)}
            for x:Float in [-10.5,10.5] {_=box(group,0.12,0.08,18,x,0.5,0,.white);_=box(group,0.25,2.1,5,x,1.5,0,.white)}
            for i in 0..<6 {let g=SCNCone(topRadius:0,bottomRadius:0.5,height:1.1);g.firstMaterial?.diffuse.contents=NSColor.orange;let n=SCNNode(geometry:g);n.position=SCNVector3(Float(i)*3-7,1,6);group.addChildNode(n)}
        } else if b.level>0 {
            let office=b.kind.contains("office") || b.kind=="Boardroom"
            let height:CGFloat=office ? 12:7
            _=box(group,21,height,19,0,Float(height/2)+0.3,0,b.kind=="Dressing room" ? cream:brick,0.2)
            for side:Float in [-1,1] {
                let slab=box(group,12.4,0.8,21,side*5.4,Float(height)+2.3,0,roof,0.1);slab.eulerAngles.z=CGFloat(side)*0.30
                for row in 0..<(office ? 2:1) {for x:Float in [-7,0,7] {
                    _=box(group,3.6,3.6,0.3,x,Float(row)*5+3.3,side*9.65,cream)
                    _=box(group,2.9,2.9,0.34,x,Float(row)*5+3.3,side*9.83,NSColor(calibratedRed:0.21,green:0.34,blue:0.38,alpha:1))
                    _=box(group,0.14,3,0.4,x,Float(row)*5+3.3,side*9.9,cream)
                }}
            }
            _=box(group,3.2,4.4,0.5,0,2.4,10,NSColor(calibratedRed:0.2,green:0.13,blue:0.08,alpha:1))
            _=box(group,6,0.5,3,0,0.4,11,pathColor)
            if ["Shop","Small shop","Large shop","Programme stall","Café","Burger bar","Restaurant"].contains(b.kind) {
                for i in 0..<12 {let awning=box(group,1.8,0.3,4.5,Float(i)*1.8-9.9,5.8,11,i%2==0 ? .systemRed:cream);awning.eulerAngles.x=0.15}
                if b.kind=="Café" {for x:Float in [-8,8] {let table=SCNCylinder(radius:2,height:0.3);table.firstMaterial?.diffuse.contents=cream;let n=SCNNode(geometry:table);n.position=SCNVector3(x,1.6,14);group.addChildNode(n)}}
            }
            if b.level>1 {_=box(group,6,CGFloat(b.level)*2,8,10,Float(b.level),0,brick)}
        }
        if b.isBuilding {scaffold(group,b)}
    }
    static let pathColor=NSColor(calibratedRed:0.64,green:0.61,blue:0.49,alpha:1)
    static func stand(_ group:SCNNode,_ b:GroundBuilding) {
        // Stand geometry is modelled with its rear extending along +Z. Rotate
        // each position so that rear always faces away from the pitch.
        // Explicit mapping avoids the former east/west inversion and makes
        // every corner deterministic.
        let facing:[String:CGFloat] = [
            "south": 0,
            "south-east": .pi / 4,
            "east": .pi / 2,
            "north-east": .pi * 3 / 4,
            "north": .pi,
            "north-west": -.pi * 3 / 4,
            "west": -.pi / 2,
            "south-west": -.pi / 4
        ]
        group.eulerAngles.y=facing[b.plotID] ?? 0
        guard b.level>0 else {return}
        let length:CGFloat=b.plotID.contains("-") ? 25:((b.plotID=="east" || b.plotID=="west") ? 78:114)
        let appearance=StandAppearance(capacity:b.capacity),spec=b.specification ?? StandSpecification()
        let depth=CGFloat(appearance.decks*appearance.rowsPerDeck)*1.0+CGFloat(appearance.decks-1)*2
        _=box(group,length,5,depth,0,2.5,Float(depth/2)-6,brick)
        for deck in 0..<appearance.decks {
            for row in 0..<appearance.rowsPerDeck {
                let index=deck*appearance.rowsPerDeck+row
                let z=Float(index)+Float(deck)*2-6,y=Float(index)*0.7+Float(deck)*3+1.5
                _=box(group,length,0.8,1,0,y,z,.darkGray)
                if spec.seated {for j in 0..<30 {_=box(group,length/32,0.45,0.65,Float(-length/2)+Float(j+1)*Float(length/31),y+0.6,z,j%10<8 ? NSColor(calibratedRed:0.65,green:0.12,blue:0.09,alpha:1):cream,0.06)}}
                else if row%2==0 {_=box(group,length,0.15,0.15,0,y+1.3,z,.lightGray)}
            }
            if deck>0 {
                let z=Float(deck*appearance.rowsPerDeck+deck*2)-7,y=Float(deck*appearance.rowsPerDeck)*0.7+Float(deck)*3
                _=box(group,length,2,0.6,0,y,z,cream)
                for k in 0..<8 {_=box(group,1.4,2.5,0.5,Float(k)*Float(length/9)-Float(length/2)+8,y,z-0.4,.darkGray)}
            }
        }
        let height=Float(appearance.decks*appearance.rowsPerDeck)*0.7+Float(appearance.decks-1)*3+5
        if spec.boxes>0 {
            let count=min(12,spec.boxes)
            for k in 0..<count {let x=Float(k+1)*Float(length/CGFloat(count+1))-Float(length/2);_=box(group,length/CGFloat(count+2),2.7,3,x,height-2,Float(depth)-6,NSColor(calibratedRed:0.25,green:0.41,blue:0.5,alpha:1))}
        }
        if spec.covered {
            let canopy=box(group,length+3,0.65,depth+4,0,height,Float(depth/2)-6,NSColor(calibratedRed:0.52,green:0.55,blue:0.52,alpha:1));canopy.eulerAngles.x = -0.08
            for i in 0..<20 {_=box(group,0.14,0.12,depth+4,Float(-length/2)+Float(i)*Float(length/19),height+0.5,Float(depth/2)-6,.lightGray)}
            for x:Float in [-Float(length/2)+3,0,Float(length/2)-3] {_=box(group,0.5,CGFloat(height),0.5,x,height/2,Float(depth)-6,.lightGray)}
        }
    }

    static func scaffold(_ group:SCNNode,_ b:GroundBuilding) {
        let w:Float=b.kind=="Stand" ? 28:23,d:Float=23,h:Float=b.kind=="Stand" ? 21:15
        if b.level==0 {_=box(group,CGFloat(w),0.3,CGFloat(d),0,0.5,0,NSColor(calibratedRed:0.46,green:0.34,blue:0.23,alpha:1))}
        for x:Float in [-w/2,w/2] {for z:Float in [-d/2,d/2] {_=box(group,0.28,CGFloat(h),0.28,x,h/2,z,.lightGray)}}
        for y in stride(from:Float(3),through:h,by:3) {for z:Float in [-d/2,d/2] {_=box(group,CGFloat(w),0.25,0.25,0,y,z,.lightGray)};for x:Float in [-w/2,w/2] {_=box(group,0.25,0.25,CGFloat(d),x,y,0,.lightGray)}}
        for i in 0..<8 {_=box(group,2,1,0.4,Float(i)*3-10,1.7,d/2+1,i%2==0 ? .systemYellow:.black)}
        _=box(group,1,27,1,w/2+2,13.5,-d/2,.systemYellow)
        _=box(group,21,0.8,0.8,w/2-6,26,-d/2,.systemYellow)
    }
}
