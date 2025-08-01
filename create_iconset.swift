import Cocoa
import CoreGraphics

// Icon sizes required for macOS
let iconSizes = [16, 32, 64, 128, 256, 512, 1024]

func createIconSet() {
    // Load the base icon (use enabled version for app icon)
    guard let baseImage = NSImage(contentsOfFile: "icon_enabled.png") else {
        print("Error: Could not load icon_enabled.png")
        return
    }
    
    // Create iconset directory
    let iconsetPath = "MacFreeze.iconset"
    let fileManager = FileManager.default
    
    // Remove existing iconset if it exists
    try? fileManager.removeItem(atPath: iconsetPath)
    try? fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
    
    // Generate icons for each size
    for size in iconSizes {
        let resizedImage = NSImage(size: NSSize(width: size, height: size))
        resizedImage.lockFocus()
        
        // Clear background
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
        
        // Draw the base image scaled to this size
        baseImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        resizedImage.unlockFocus()
        
        // Save the icon
        if let tiffData = resizedImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            let filename = "icon_\(size)x\(size).png"
            let filepath = "\(iconsetPath)/\(filename)"
            try? pngData.write(to: URL(fileURLWithPath: filepath))
            print("Created: \(filename)")
        }
    }
    
    // Create icns file using iconutil
    let process = Process()
    process.launchPath = "/usr/bin/iconutil"
    process.arguments = ["-c", "icns", iconsetPath]
    process.currentDirectoryPath = FileManager.default.currentDirectoryPath
    
    do {
        try process.run()
        process.waitUntilExit()
        print("Created: MacFreeze.icns")
    } catch {
        print("Error creating icns file: \(error)")
    }
}

createIconSet() 