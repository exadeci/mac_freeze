import Cocoa
import CoreGraphics

// Create freezer icon using icons from icons/ directory
func createIcon(isEnabled: Bool = true) {
    let size = 1024
    
    // Load the appropriate base image from icons/ directory
    let baseImageName = isEnabled ? "icons/freezer_enabled.png" : "icons/freezer_disabled.png"
    guard let baseImage = NSImage(contentsOfFile: baseImageName) else {
        print("Error: Could not load \(baseImageName)")
        return
    }
    
    // Create new image with proper size
    let newImage = NSImage(size: NSSize(width: size, height: size))
    newImage.lockFocus()
    
    // Clear background
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    
    // Draw the base image scaled to fit
    baseImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    
    newImage.unlockFocus()
    
    // Save the image
    if let tiffData = newImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let filename = isEnabled ? "icon_enabled.png" : "icon_disabled.png"
        let url = URL(fileURLWithPath: filename)
        try? pngData.write(to: url)
        print("Icon saved as \(filename)")
    }
}

// Create both enabled and disabled icons
createIcon(isEnabled: true)
createIcon(isEnabled: false) 