import Foundation
import Vision
import AppKit

let a = CommandLine.arguments
guard a.count > 1 else { exit(1) }
let path = a[1]
let langs = a.count > 2 ? a[2].split(separator: ",").map(String.init) : ["ru-RU", "en-US"]
let correction = a.count > 3 ? (a[3] == "1") : true
let scale = a.count > 4 ? (Double(a[4]) ?? 1.0) : 1.0

guard let img = NSImage(contentsOfFile: path),
      var cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("не открыть файл\n".data(using: .utf8)!); exit(1)
}
if scale != 1.0 {
    let w = Int(Double(cg.width) * scale), h = Int(Double(cg.height) * scale)
    if let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                           space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        if let out = ctx.makeImage() { cg = out }
    }
}
let req = VNRecognizeTextRequest()
req.recognitionLevel = .accurate
req.recognitionLanguages = langs
req.usesLanguageCorrection = correction
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
try handler.perform([req])
var lines: [(CGFloat, CGFloat, Float, String)] = []
for obs in req.results ?? [] {
    guard let c = obs.topCandidates(1).first else { continue }
    let bb = obs.boundingBox
    lines.append((1 - bb.midY, bb.minX, c.confidence, c.string))
}
lines.sort { x, y in abs(x.0 - y.0) < 0.012 ? x.1 < y.1 : x.0 < y.0 }
for l in lines { print(String(format: "%.2f\t%@", l.2, l.3)) }
