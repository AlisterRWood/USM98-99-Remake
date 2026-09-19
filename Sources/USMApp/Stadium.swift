import SwiftUI
import Combine
import SceneKit

struct StadiumView: NSViewRepresentable {
    var capacity:Int
    func makeNSView(context:Context)->SCNView {
        let view=SCNView();view.scene=makeScene();view.backgroundColor=NSColor(red:0.055,green:0.09,blue:0.12,alpha:1)
        view.antialiasingMode = .multisampling4X;view.allowsCameraControl=true;view.autoenablesDefaultLighting=false
        view.defaultCameraController.minimumVerticalAngle=18;view.defaultCameraController.maximumVerticalAngle=75
        return view
    }
    func updateNSView(_ view:SCNView,context:Context) {
        let level=CGFloat(min(5,capacity/15000))
        view.scene?.rootNode.childNode(withName:"expansion",recursively:true)?.scale=SCNVector3(1,1+level*0.12,1)
    }
    func makeScene()->SCNScene {
        let scene=SCNScene();let root=scene.rootNode
        func box(_ x:CGFloat,_ y:CGFloat,_ z:CGFloat,_ pos:SCNVector3,_ color:NSColor,_ chamfer:CGFloat=0)->SCNNode {
            let geo=SCNBox(width:x,height:y,length:z,chamferRadius:chamfer);geo.firstMaterial?.diffuse.contents=color;geo.firstMaterial?.roughness.contents=0.85
            let n=SCNNode(geometry:geo);n.position=pos;n.castsShadow=true;root.addChildNode(n);return n
        }
        let slate=NSColor(red:0.13,green:0.21,blue:0.27,alpha:1)
        _=box(155,2,124,SCNVector3(0,-2,0),NSColor(red:0.10,green:0.16,blue:0.18,alpha:1),3)
        _=box(110,0.3,72,SCNVector3(0,0,0),NSColor(red:0.16,green:0.34,blue:0.23,alpha:1))
        for i in 0..<12 { _=box(8.7,0.05,68,SCNVector3(-48+Float(i)*8.7,0.2,0),NSColor(red:0.16,green:i%2==0 ? 0.40:0.36,blue:0.25,alpha:1)) }
        let white=NSColor.white.withAlphaComponent(0.8)
        for z:Float in [-33,33] { _=box(104,0.08,0.22,SCNVector3(0,0.3,z),white) }
        for x:Float in [-52,0,52] { _=box(0.22,0.08,66,SCNVector3(x,0.3,0),white) }
        for x:Float in [-52,52] {
            let sign:Float=x<0 ? 1:-1
            _=box(0.22,0.08,36,SCNVector3(x+sign*16,0.3,0),white)
            for z:Float in [-18,18] { _=box(16,0.08,0.22,SCNVector3(x+sign*8,0.3,z),white) }
            _=box(0.3,3,7.4,SCNVector3(x,1.5,0),white)
        }
        let torus=SCNTorus(ringRadius:9,pipeRadius:0.12);torus.firstMaterial?.diffuse.contents=white
        let circle=SCNNode(geometry:torus);circle.position=SCNVector3(0,0.3,0);root.addChildNode(circle)
        let stand=SCNNode();stand.name="expansion";root.addChildNode(stand)
        for side:Float in [-1,1] {
            for tier in 0..<8 {
                let t=Float(tier)
                let node=box(112,1.4,2.1,SCNVector3(0,1+t*1.3,side*(39+t*1.65)),slate)
                node.removeFromParentNode();stand.addChildNode(node)
                for row in 0..<48 {
                    _=box(1.45,0.55,0.9,SCNVector3(-53+Float(row)*2.25,2+t*1.3,side*(39+t*1.65)),row%8<4 ? NSColor(red:0.65,green:0.23,blue:0.22,alpha:1):NSColor(red:0.81,green:0.81,blue:0.72,alpha:1))
                }
            }
            _=box(119,1,16,SCNVector3(0,15,side*49),NSColor(red:0.31,green:0.40,blue:0.45,alpha:1),0.5)
            for tier in 0..<7 { _=box(2,1.4,74,SCNVector3(side*(57+Float(tier)*1.6),1+Float(tier)*1.3,0),slate) }
            _=box(12,1,81,SCNVector3(side*64,13,0),NSColor(red:0.24,green:0.34,blue:0.41,alpha:1),0.5)
        }
        for x:Float in [-65,65] { for z:Float in [-47,47] {
            _=box(0.8,29,0.8,SCNVector3(x,14,z),.lightGray)
            let lightBox=box(8,2.5,1,SCNVector3(x,29,z),.white)
            lightBox.geometry?.firstMaterial?.emission.contents=NSColor.white
        } }
        _=box(20,5,12,SCNVector3(-53,1,-57),slate,0.5)
        for i in 0..<9 { _=box(3,1.2,5,SCNVector3(36+Float(i%5)*6,0,-58+Float(i/5)*7),NSColor(red:0.35,green:0.45,blue:0.46,alpha:1),0.8) }
        let ambient=SCNNode();ambient.light=SCNLight();ambient.light!.type = .ambient;ambient.light!.intensity=700;ambient.light!.color=NSColor(red:0.6,green:0.72,blue:0.86,alpha:1);root.addChildNode(ambient)
        let sun=SCNNode();sun.light=SCNLight();sun.light!.type = .directional;sun.light!.intensity=1600;sun.light!.castsShadow=true;sun.light!.shadowRadius=5;sun.light!.shadowMapSize=CGSize(width:2048,height:2048);sun.eulerAngles=SCNVector3(-0.8,-0.4,0);root.addChildNode(sun)
        let camera=SCNNode();camera.camera=SCNCamera();camera.camera!.usesOrthographicProjection=true;camera.camera!.orthographicScale=70;camera.camera!.zFar=1000;camera.position=SCNVector3(145,135,165);camera.look(at:SCNVector3(0,0,0));root.addChildNode(camera)
        scene.background.contents=NSColor(red:0.055,green:0.09,blue:0.12,alpha:1)
        return scene
    }
}
