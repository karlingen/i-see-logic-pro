// Draws the app icon as a 1024 by 1024 PNG file. app/build.sh turns it into AppIcon.icns.
// The icon is a disc that is dark on the left, like stock Logic Pro, and light on the right,
// like the theme. A multicolor eye at the center stands for the name "I See".
import AppKit

let CANVAS = 1024.0
// The macOS icon grid: an 824 point rounded square in the center of the canvas.
let BODY = 824.0
let RADIUS = 185.0
let DISC_RADIUS = 330.0
let IRIS_RADIUS = 118.0
let GROOVE_STEP = 0.045
let GROOVE_END = 0.42
let IRIS_COLORS = [
   NSColor(srgbRed: 0.88, green: 0.78, blue: 0.22, alpha: 1),
   NSColor(srgbRed: 0.55, green: 0.8, blue: 0.27, alpha: 1),
   NSColor(srgbRed: 0.24, green: 0.72, blue: 0.7, alpha: 1),
   NSColor(srgbRed: 0.33, green: 0.55, blue: 0.9, alpha: 1),
   NSColor(srgbRed: 0.6, green: 0.45, blue: 0.85, alpha: 1),
   NSColor(srgbRed: 0.9, green: 0.45, blue: 0.6, alpha: 1),
]

/**
 * Draws a disc with grooves.
 *
 * @param center NSPoint - the center of the disc
 * @param isLight Bool - true for the light disc, false for the dark disc
 */
func drawDisc(center: NSPoint, isLight: Bool) {
   let rect = NSRect(x: center.x - DISC_RADIUS, y: center.y - DISC_RADIUS, width: 2 * DISC_RADIUS, height: 2 * DISC_RADIUS)
   let levels = isLight ? [ 1, 0.9, 0.97, 0.86 ] : [ 0.24, 0.12, 0.2, 0.08 ]
   let face = NSGradient(colors: levels.map { (level) in return NSColor(white: level, alpha: 1) })!
   let shadow = NSShadow()
   var groove = DISC_RADIUS * 0.96

   NSGraphicsContext.saveGraphicsState()
   shadow.shadowColor = NSColor(white: 0, alpha: 0.25)
   shadow.shadowBlurRadius = 24
   shadow.shadowOffset = NSSize(width: 0, height: 8)
   shadow.set()
   NSColor(white: isLight ? 0.95 : 0.15, alpha: 1).setFill()
   NSBezierPath(ovalIn: rect).fill()
   NSGraphicsContext.restoreGraphicsState()
   face.draw(in: NSBezierPath(ovalIn: rect), angle: 35)
   NSColor(white: isLight ? 0.55 : 0.6, alpha: isLight ? 0.18 : 0.22).setStroke()
   while groove > DISC_RADIUS * GROOVE_END {
      let ring = NSBezierPath(ovalIn: NSRect(x: center.x - groove, y: center.y - groove, width: 2 * groove, height: 2 * groove))

      ring.lineWidth = 2
      ring.stroke()
      groove -= DISC_RADIUS * GROOVE_STEP
   }
}

/**
 * Draws the eye at the center of the disc: a multicolor iris, a pupil and a highlight.
 *
 * @param center NSPoint - the center of the eye
 */
func drawEye(center: NSPoint) {
   let pupil = IRIS_RADIUS * 0.45
   let highlight = IRIS_RADIUS * 0.2
   let sector = 360.0 / Double(IRIS_COLORS.count)

   for (i, color) in IRIS_COLORS.enumerated() {
      let wedge = NSBezierPath()

      wedge.move(to: center)
      wedge.appendArc(withCenter: center, radius: IRIS_RADIUS, startAngle: Double(i) * sector - 90,
         endAngle: Double(i + 1) * sector - 90)
      wedge.close()
      color.setFill()
      wedge.fill()
   }
   NSColor(white: 0.08, alpha: 1).setFill()
   NSBezierPath(ovalIn: NSRect(x: center.x - pupil, y: center.y - pupil, width: 2 * pupil, height: 2 * pupil)).fill()
   NSColor.white.setFill()
   NSBezierPath(ovalIn: NSRect(x: center.x + pupil * 0.18, y: center.y + pupil * 0.2, width: highlight, height: highlight)).fill()
}

/**
 * Draws the whole icon into a bitmap.
 *
 * @return NSBitmapImageRep - the 1024 by 1024 icon
 */
func drawIcon() -> NSBitmapImageRep {
   let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(CANVAS), pixelsHigh: Int(CANVAS), bitsPerSample: 8,
      samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
   let body = NSRect(x: (CANVAS - BODY) / 2, y: (CANVAS - BODY) / 2, width: BODY, height: BODY)
   let shape = NSBezierPath(roundedRect: body, xRadius: RADIUS, yRadius: RADIUS)
   let center = NSPoint(x: body.midX, y: body.midY)
   let darkHalf = NSRect(x: body.minX, y: body.minY, width: BODY / 2, height: BODY)
   let lightHalf = NSRect(x: body.midX, y: body.minY, width: BODY / 2, height: BODY)
   let shadow = NSShadow()

   NSGraphicsContext.saveGraphicsState()
   NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
   NSGraphicsContext.saveGraphicsState()
   shadow.shadowColor = NSColor(white: 0, alpha: 0.3)
   shadow.shadowBlurRadius = 20
   shadow.shadowOffset = NSSize(width: 0, height: -10)
   shadow.set()
   NSColor.white.setFill()
   shape.fill()
   NSGraphicsContext.restoreGraphicsState()
   shape.addClip()
   NSColor(white: 0.13, alpha: 1).setFill()
   darkHalf.fill()
   NSGradient(starting: NSColor(white: 0.86, alpha: 1), ending: NSColor(white: 0.97, alpha: 1))!.draw(in: lightHalf, angle: 90)
   for (half, isLight) in [ (darkHalf, false), (lightHalf, true) ] {
      NSGraphicsContext.saveGraphicsState()
      half.clip()
      drawDisc(center: center, isLight: isLight)
      NSGraphicsContext.restoreGraphicsState()
   }
   drawEye(center: center)
   NSGraphicsContext.restoreGraphicsState()
   return rep
}

let png = drawIcon().representation(using: .png, properties: [:])!

try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
