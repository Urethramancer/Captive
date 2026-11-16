// Original Amiga asset conversion only; no game code or GPL-derived material.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/extracted"
let output = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ".build/data"
let code = try Data(contentsOf: URL(fileURLWithPath: root + "/federation"))
guard code.count == 95872 else { fatalError("Unsupported original executable for palette extraction") }
var palette = [UInt8]()
for i in 0..<32 {
 let n = Int(code[0x644+i*2])*256 + Int(code[0x645+i*2])
 guard n < 4096 else { fatalError("Invalid original palette") }
 palette += [UInt8((n>>8&15)*17),UInt8((n>>4&15)*17),UInt8((n&15)*17)]
}
func extract(_ source:String,_ name:String,_ x:Int,_ y:Int,_ width:Int,_ height:Int,_ masked:Bool) throws {
 let data = try Data(contentsOf: URL(fileURLWithPath: root + "/" + source))
 guard data.count == 40000, x >= 0, y >= 0, x+width <= 320, y+height <= 200 else { fatalError("Invalid original sheet rectangle") }
 var pixels = Data(capacity: width*height*4)
 for row in y..<y+height { for col in x..<x+width {
  var index = 0
  for plane in 0..<5 { index |= Int(data[plane*8000+row*40+col/8]>>(7-col%8)&1)<<plane }
  let alpha:UInt8 = masked && index == 0 ? 0 : 255
  pixels.append(alpha == 0 ? 0 : palette[index*3]); pixels.append(alpha == 0 ? 0 : palette[index*3+1]); pixels.append(alpha == 0 ? 0 : palette[index*3+2]); pixels.append(alpha)
 } }
 let provider = CGDataProvider(data:pixels as CFData)!
 let image = CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent)!
 let url=URL(fileURLWithPath:output+"/"+name+".png")
 guard let destination=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil) else { throw NSError(domain:"original-comparison",code:1) }
 CGImageDestinationAddImage(destination,image,nil)
 guard CGImageDestinationFinalize(destination) else { throw NSError(domain:"original-comparison",code:2) }
}
try extract("Fed7-A.pic","original-wall",0,36,110,88,false)
try extract("Fed2-A.pic","original-door",62,0,35,69,false)
try extract("Fed6-B.pic","original-tree",144,84,32,49,true)
try extract("Fed6-A.pic","original-scavenger",135,118,22,27,true)
// Cross-version comparison exception: the Atari Brains figure is a composite
// not yet mapped to a supplied Amiga sheet. Keep this derived image ignored.
let brainsURL=URL(fileURLWithPath:".build/recovery/brains-ref.png")
if let src=CGImageSourceCreateWithURL(brainsURL as CFURL,nil), let image=CGImageSourceCreateImageAtIndex(src,0,nil), let crop=image.cropping(to:CGRect(x:127,y:128,width:40,height:80)) {
 var pixels=[UInt8](repeating:0,count:40*80*4)
 let context=CGContext(data:&pixels,width:40,height:80,bitsPerComponent:8,bytesPerRow:160,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 context.draw(crop,in:CGRect(x:0,y:0,width:40,height:80))
 for y in 0..<80 { for x in 0..<40 {
  let at=(y*40+x)*4, r=Int(pixels[at]), g=Int(pixels[at+1]), b=Int(pixels[at+2])
  // Pale character pixels and the slim brown staff, excluding floor masonry.
  let staff=x>=27 && x<=33 && y<73 && r>65 && r>g && g>b
  let body=x>=3 && x<=28 && y<77 && r>135 && g>110 && b>60 && r>=g
  if !staff && !body { pixels[at]=0;pixels[at+1]=0;pixels[at+2]=0;pixels[at+3]=0 }
 } }
 let out=CGContext(data:&pixels,width:40,height:80,bitsPerComponent:8,bytesPerRow:160,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
 let dest=CGImageDestinationCreateWithURL(URL(fileURLWithPath:output+"/original-brains.png") as CFURL,UTType.png.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(dest,out,nil)
 guard CGImageDestinationFinalize(dest) else { fatalError("Could not write original Brains comparison") }
}
