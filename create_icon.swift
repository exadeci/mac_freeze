import Cocoa
import CoreGraphics

// Create a chest freezer icon
func createIcon(isEnabled: Bool = true) {
    let size = 1024
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    
    // Set background
    context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    
    let centerX = CGFloat(size/2)
    let centerY = CGFloat(size/2)
    let freezerWidth = CGFloat(Double(size) * 0.6)
    let freezerHeight = CGFloat(Double(size) * 0.5)
    let lidHeight = CGFloat(Double(size) * 0.15)
    let cornerRadius = CGFloat(Double(size) * 0.03)
    
    // Choose colors based on enabled state
    let bodyColor: CGColor
    let borderColor: CGColor
    
    if isEnabled {
        // Blue when enabled
        bodyColor = CGColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        borderColor = CGColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0)
    } else {
        // White when disabled
        bodyColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        borderColor = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    
    // Draw freezer body with rounded corners
    let bodyRect = CGRect(
        x: centerX - freezerWidth/2,
        y: centerY - freezerHeight/2,
        width: freezerWidth,
        height: freezerHeight
    )
    
    // Create rounded rectangle path for body
    let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Freezer body fill
    context.setFillColor(bodyColor)
    context.addPath(bodyPath)
    context.fillPath()
    
    // Freezer border (thicker)
    context.setStrokeColor(borderColor)
    context.setLineWidth(16)
    context.addPath(bodyPath)
    context.strokePath()
    
    // Draw lid with rounded corners
    let lidRect = CGRect(
        x: centerX - freezerWidth/2,
        y: centerY + freezerHeight/2 - lidHeight,
        width: freezerWidth,
        height: lidHeight
    )
    
    // Create rounded rectangle path for lid
    let lidPath = CGPath(roundedRect: lidRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Lid fill
    context.setFillColor(bodyColor)
    context.addPath(lidPath)
    context.fillPath()
    
    // Lid border (thicker)
    context.setStrokeColor(borderColor)
    context.setLineWidth(16)
    context.addPath(lidPath)
    context.strokePath()
    
    // Draw handle
    let handleWidth = freezerWidth * 0.3
    let handleHeight = lidHeight * 0.3
    let handleRect = CGRect(
        x: centerX - handleWidth/2,
        y: lidRect.midY - handleHeight/2,
        width: handleWidth,
        height: handleHeight
    )
    
    // Handle (dark gray)
    context.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
    context.fill(handleRect)
    
    // Handle border
    context.setStrokeColor(CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0))
    context.setLineWidth(8)
    context.stroke(handleRect)
    
    // Draw feet
    let footWidth = freezerWidth * 0.15
    let footHeight = CGFloat(Double(size) * 0.05)
    let footSpacing = freezerWidth * 0.25
    
    for i in 0..<3 {
        let footX = centerX - footSpacing + CGFloat(i) * footSpacing
        let footY = centerY + freezerHeight/2 + footHeight/2
        
        let footRect = CGRect(
            x: footX - footWidth/2,
            y: footY - footHeight/2,
            width: footWidth,
            height: footHeight
        )
        
        // Foot (dark gray)
        context.setFillColor(CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0))
        context.fill(footRect)
        
        // Foot border
        context.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        context.setLineWidth(6)
        context.stroke(footRect)
    }
    
    // Add some frost/ice effect when enabled
    if isEnabled {
        // Draw frost pattern
        context.setStrokeColor(CGColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9))
        context.setLineWidth(6)
        
        for i in 0..<5 {
            let y = bodyRect.minY + bodyRect.height * 0.2 + CGFloat(i) * bodyRect.height * 0.15
            let startX = bodyRect.minX + bodyRect.width * 0.1
            let endX = bodyRect.maxX - bodyRect.width * 0.1
            
            context.move(to: CGPoint(x: startX, y: y))
            context.addLine(to: CGPoint(x: endX, y: y))
        }
        context.strokePath()
    }
    
    // Save the image
    if let image = context.makeImage() {
        let bitmap = NSBitmapImageRep(cgImage: image)
        if let data = bitmap.representation(using: .png, properties: [:]) {
            let filename = isEnabled ? "icon_enabled.png" : "icon_disabled.png"
            let url = URL(fileURLWithPath: filename)
            try? data.write(to: url)
            print("Icon saved as \(filename)")
        }
    }
}

// Create both enabled and disabled icons
createIcon(isEnabled: true)
createIcon(isEnabled: false) 