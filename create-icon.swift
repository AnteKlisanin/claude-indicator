#!/usr/bin/env swift

import AppKit
import Foundation

// Create icon at various sizes
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x")
]

// Siri-style colors
let siriColors: [NSColor] = [
    NSColor(red: 1.0, green: 0.18, blue: 0.57, alpha: 1.0),   // Pink
    NSColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0),  // Purple
    NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),    // Blue
    NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),  // Cyan
    NSColor(red: 0.2, green: 0.78, blue: 0.65, alpha: 1.0),   // Teal
    NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),    // Orange
    NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),   // Red
]

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let center = NSPoint(x: size / 2, y: size / 2)

    // Background - dark rounded square
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.05, dy: size * 0.05),
                               xRadius: size * 0.2, yRadius: size * 0.2)
    NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0).setFill()
    bgPath.fill()

    // Ring parameters
    let ringRadius = size * 0.32
    let ringWidth = size * 0.09

    // Draw glow effect for each color segment
    let segmentCount = siriColors.count
    for glowLayer in stride(from: 4, through: 1, by: -1) {
        let glowAlpha = 0.15 / Double(glowLayer)
        let glowOffset = CGFloat(glowLayer) * ringWidth * 0.4

        for i in 0..<segmentCount {
            let startAngle = CGFloat(i) / CGFloat(segmentCount) * 360 - 90
            let endAngle = CGFloat(i + 1) / CGFloat(segmentCount) * 360 - 90

            let path = NSBezierPath()
            path.appendArc(withCenter: center, radius: ringRadius + glowOffset, startAngle: startAngle, endAngle: endAngle)
            path.lineWidth = ringWidth * 0.6
            path.lineCapStyle = .round

            siriColors[i].withAlphaComponent(glowAlpha).setStroke()
            path.stroke()
        }
    }

    // Draw main Siri gradient ring
    for i in 0..<segmentCount {
        let startAngle = CGFloat(i) / CGFloat(segmentCount) * 360 - 90
        let endAngle = CGFloat(i + 1) / CGFloat(segmentCount) * 360 - 90

        let path = NSBezierPath()
        path.appendArc(withCenter: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle)
        path.lineWidth = ringWidth
        path.lineCapStyle = .round

        siriColors[i].setStroke()
        path.stroke()
    }

    // Inner bright highlight ring
    for i in 0..<segmentCount {
        let startAngle = CGFloat(i) / CGFloat(segmentCount) * 360 - 90
        let endAngle = CGFloat(i + 1) / CGFloat(segmentCount) * 360 - 90

        let path = NSBezierPath()
        path.appendArc(withCenter: center, radius: ringRadius - ringWidth * 0.25, startAngle: startAngle, endAngle: endAngle)
        path.lineWidth = ringWidth * 0.2
        path.lineCapStyle = .round

        siriColors[i].withAlphaComponent(0.6).setStroke()
        path.stroke()
    }

    // Center infinity symbol
    let infinityWidth = size * 0.18
    let infinityHeight = size * 0.09
    let lineWidth = size * 0.025

    let infinityPath = NSBezierPath()

    // Draw infinity symbol (two connected loops)
    // Left loop
    let leftCenter = NSPoint(x: center.x - infinityWidth * 0.25, y: center.y)
    let loopRadius = infinityHeight * 0.5

    // Right loop
    let rightCenter = NSPoint(x: center.x + infinityWidth * 0.25, y: center.y)

    // Create figure-8 path
    infinityPath.move(to: center)

    // Right loop (clockwise)
    infinityPath.appendArc(withCenter: rightCenter, radius: loopRadius,
                           startAngle: 180, endAngle: -180, clockwise: true)

    // Left loop (counter-clockwise)
    infinityPath.appendArc(withCenter: leftCenter, radius: loopRadius,
                           startAngle: 0, endAngle: 360, clockwise: false)

    infinityPath.lineWidth = lineWidth
    infinityPath.lineCapStyle = .round
    infinityPath.lineJoinStyle = .round

    // Draw with a nice purple/blue gradient color
    NSColor(red: 0.6, green: 0.5, blue: 0.95, alpha: 0.9).setStroke()
    infinityPath.stroke()

    image.unlockFocus()

    return image
}

// Create iconset directory
let iconsetPath = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate all sizes
for (size, name) in sizes {
    let image = createIcon(size: size)

    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(iconsetPath)/\(name).png"
        try! pngData.write(to: URL(fileURLWithPath: path))
        print("Created \(path)")
    }
}

print("\nIconset created. Converting to .icns...")

// Convert to icns using iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Successfully created AppIcon.icns")

    // Clean up iconset
    try? FileManager.default.removeItem(atPath: iconsetPath)
} else {
    print("Failed to create .icns file")
}
