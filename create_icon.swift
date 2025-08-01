import Cocoa
import CoreGraphics

// Create a simple snowflake icon
func createIcon() {
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
    context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    
    // Draw snowflake
    context.setStrokeColor(CGColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0))
    context.setLineWidth(8)
    
    let center = CGPoint(x: size/2, y: size/2)
    let radius = CGFloat(size/3)
    
    // Draw main snowflake structure
    for i in 0..<6 {
        let angle = CGFloat(i) * .pi / 3
        let endPoint = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        
        context.move(to: center)
        context.addLine(to: endPoint)
        
        // Add smaller branches
        let branchLength = radius * 0.4
        let branchPoint = CGPoint(
            x: center.x + cos(angle) * branchLength,
            y: center.y + sin(angle) * branchLength
        )
        
        let perpAngle1 = angle + .pi/2
        let perpAngle2 = angle - .pi/2
        
        let branch1 = CGPoint(
            x: branchPoint.x + cos(perpAngle1) * branchLength * 0.3,
            y: branchPoint.y + sin(perpAngle1) * branchLength * 0.3
        )
        
        let branch2 = CGPoint(
            x: branchPoint.x + cos(perpAngle2) * branchLength * 0.3,
            y: branchPoint.y + sin(perpAngle2) * branchLength * 0.3
        )
        
        context.move(to: branchPoint)
        context.addLine(to: branch1)
        context.move(to: branchPoint)
        context.addLine(to: branch2)
    }
    
    context.strokePath()
    
    // Save the image
    if let image = context.makeImage() {
        let bitmap = NSBitmapImageRep(cgImage: image)
        if let data = bitmap.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: "icon.png")
            try? data.write(to: url)
            print("Icon saved as icon.png")
        }
    }
}

createIcon() 