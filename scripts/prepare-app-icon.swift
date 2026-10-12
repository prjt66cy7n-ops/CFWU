import AppKit
import ImageIO
import UniformTypeIdentifiers

// Asset export during the native build: preserve the painted master and produce
// Apple's required opaque 1024px marketing icon without changing its composition.
guard CommandLine.arguments.count == 3 else { fatalError("Expected icon master and output paths") }
let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Could not decode the app icon master")
}
context.setFillColor(CGColor(red: 0.5, green: 0.75, blue: 1, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
guard let exported = context.makeImage() else { fatalError("Could not render app icon") }
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
let temporary = outputURL.deletingLastPathComponent().appendingPathComponent("icon-export-\(UUID().uuidString).png")
guard let destination = CGImageDestinationCreateWithURL(temporary as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create icon export")
}
CGImageDestinationAddImage(destination, exported, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write icon export") }
if FileManager.default.fileExists(atPath: outputURL.path) { try FileManager.default.removeItem(at: outputURL) }
try FileManager.default.moveItem(at: temporary, to: outputURL)
print("Exported opaque 1024 × 1024 app icon")
