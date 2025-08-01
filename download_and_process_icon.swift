import Cocoa
import Foundation

// Download and process the freezer icon
func downloadAndProcessIcon() {
    let urlString = "https://static.vecteezy.com/system/resources/previews/009/687/326/non_2x/sign-of-the-freezer-symbol-is-isolated-on-a-white-background-freezer-icon-color-editable-free-vector.jpg"
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    
    // Download the image
    print("Downloading freezer icon...")
    guard let data = try? Data(contentsOf: url),
          let originalImage = NSImage(data: data) else {
        print("Failed to download or load image")
        return
    }
    
    print("Image downloaded successfully")
    
    // Create a new image with transparent background
    let size = NSSize(width: 1024, height: 1024)
    let newImage = NSImage(size: size)
    
    newImage.lockFocus()
    
    // Clear background
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size.width, height: size.height).fill()
    
    // Draw the original image scaled to fit
    originalImage.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height))
    
    newImage.unlockFocus()
    
    // Save the processed image
    if let tiffData = newImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let url = URL(fileURLWithPath: "freezer_original.png")
        try? pngData.write(to: url)
        print("Saved processed image as freezer_original.png")
    }
    
    // Create blue version
    createBlueVersion(from: newImage)
}

// Create blue version of the freezer icon
func createBlueVersion(from originalImage: NSImage) {
    let size = NSSize(width: 1024, height: 1024)
    let blueImage = NSImage(size: size)
    
    blueImage.lockFocus()
    
    // Clear background
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size.width, height: size.height).fill()
    
    // Apply blue tint
    let blueFilter = CIFilter(name: "CIColorControls")
    blueFilter?.setValue(CIImage(data: originalImage.tiffRepresentation!), forKey: kCIInputImageKey)
    blueFilter?.setValue(0.8, forKey: kCIInputSaturationKey) // Reduce saturation
    blueFilter?.setValue(1.2, forKey: kCIInputBrightnessKey) // Slightly brighter
    
    if let outputImage = blueFilter?.outputImage {
        let rep = NSCIImageRep(ciImage: outputImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        // Draw with blue tint
        let blueTint = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.8)
        blueTint.set()
        nsImage.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height), from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
    }
    
    blueImage.unlockFocus()
    
    // Save blue version
    if let tiffData = blueImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let url = URL(fileURLWithPath: "freezer_blue.png")
        try? pngData.write(to: url)
        print("Saved blue version as freezer_blue.png")
    }
}

downloadAndProcessIcon() 