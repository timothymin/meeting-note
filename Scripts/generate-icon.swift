import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift generate-icon.swift OUTPUT.png|OUTPUT.icns\n", stderr)
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else { exit(1) }
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let outer = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 210, yRadius: 210)
NSGradient(colors: [
    NSColor(calibratedRed: 0.20, green: 0.48, blue: 0.98, alpha: 1),
    NSColor(calibratedRed: 0.42, green: 0.24, blue: 0.92, alpha: 1)
])!.draw(in: outer, angle: -45)

let inner = NSBezierPath(roundedRect: NSRect(x: 150, y: 150, width: 724, height: 724), xRadius: 160, yRadius: 160)
NSColor.black.withAlphaComponent(0.16).setFill()
inner.fill()

let heights: [CGFloat] = [190, 330, 480, 620, 480, 330, 190]
let barWidth: CGFloat = 56
let gap: CGFloat = 35
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
var x = (1024 - totalWidth) / 2

NSColor.white.setFill()
for height in heights {
    let rect = NSRect(x: x, y: (1024 - height) / 2, width: barWidth, height: height)
    NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
    x += barWidth + gap
}

image.unlockFocus()

func pngData(from source: NSImage, size: CGFloat) -> Data? {
    let target = NSImage(size: NSSize(width: size, height: size))
    target.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    source.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    target.unlockFocus()
    guard let tiff = target.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
    return bitmap.representation(using: .png, properties: [:])
}

func bigEndianData(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return Data(bytes: &number, count: MemoryLayout<UInt32>.size)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
if output.pathExtension.lowercased() == "icns" {
    let specifications: [(String, CGFloat)] = [
        ("ic10", 1024), ("ic09", 512), ("ic14", 512), ("ic08", 256),
        ("ic13", 256), ("ic07", 128), ("ic12", 64), ("icp6", 64),
        ("ic11", 32), ("icp5", 32), ("icp4", 16)
    ]
    var chunks = Data()
    for (type, dimension) in specifications {
        guard let png = pngData(from: image, size: dimension) else { exit(1) }
        chunks.append(Data(type.utf8))
        chunks.append(bigEndianData(png.count + 8))
        chunks.append(png)
    }
    var icon = Data("icns".utf8)
    icon.append(bigEndianData(chunks.count + 8))
    icon.append(chunks)
    try icon.write(to: output, options: .atomic)
} else {
    guard let png = pngData(from: image, size: 1024) else { exit(1) }
    try png.write(to: output, options: .atomic)
}
