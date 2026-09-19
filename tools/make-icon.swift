import AppKit
import Foundation
let destination=CommandLine.arguments[1]
let image=NSImage(size:NSSize(width:1024,height:1024))
image.lockFocus()
let rect=NSRect(x:45,y:45,width:934,height:934)
NSColor(calibratedRed:0.04,green:0.08,blue:0.11,alpha:1).setFill()
NSBezierPath(roundedRect:rect,xRadius:200,yRadius:200).fill()
let shield=NSBezierPath();shield.move(to:NSPoint(x:240,y:775));shield.line(to:NSPoint(x:784,y:775));shield.line(to:NSPoint(x:770,y:425));shield.curve(to:NSPoint(x:512,y:195),controlPoint1:NSPoint(x:750,y:315),controlPoint2:NSPoint(x:630,y:235));shield.curve(to:NSPoint(x:254,y:425),controlPoint1:NSPoint(x:390,y:235),controlPoint2:NSPoint(x:275,y:315));shield.close()
NSColor(calibratedRed:0.67,green:0.91,blue:0.43,alpha:1).setFill();shield.fill()
let title="USM" as NSString
let attrs:[NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:145,weight:.black),.foregroundColor:NSColor(calibratedRed:0.04,green:0.08,blue:0.11,alpha:1)]
let size=title.size(withAttributes:attrs);title.draw(at:NSPoint(x:(1024-size.width)/2,y:495),withAttributes:attrs)
let year="98 / 99" as NSString
let small:[NSAttributedString.Key:Any]=[.font:NSFont.monospacedSystemFont(ofSize:50,weight:.bold),.foregroundColor:NSColor(calibratedRed:0.04,green:0.08,blue:0.11,alpha:1)]
let ys=year.size(withAttributes:small);year.draw(at:NSPoint(x:(1024-ys.width)/2,y:400),withAttributes:small)
image.unlockFocus()
try FileManager.default.createDirectory(atPath:destination,withIntermediateDirectories:true)
for size in [16,32,128,256,512] {
 for scale in [1,2] {
  let px=size*scale
  let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:px,pixelsHigh:px,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
  NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
  image.draw(in:NSRect(x:0,y:0,width:px,height:px));NSGraphicsContext.restoreGraphicsState()
  let suffix=scale==1 ? "":"@2x"
  try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:destination).appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
 }
}
