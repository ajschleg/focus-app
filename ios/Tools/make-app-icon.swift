// Generates the app icon: a warm ensō-like disc sliced clean through, the
// two halves pushed apart along a diagonal katana cut with a blade streak in
// the gap. FocusSlice, literally.
//
// Rerun after tweaking any constant below:
//   swift ios/Tools/make-app-icon.swift
// Writes 1024x1024 PNG to ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png
// (iOS masks the rounded corners itself — the asset stays full-bleed square.)

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let center = CGPoint(x: 512, y: 512)
let discRadius: CGFloat = 320
/// Half the gap the cut opens between the disc halves.
let separation: CGFloat = 34
/// How far each half slides *along* the cut — the just-sliced shear that
/// makes the two arcs visibly misalign.
let slide: CGFloat = 46
/// The blade streak: half-length along the cut, half-width at the middle.
let streakReach: CGFloat = 470
let streakWidth: CGFloat = 13

// 45-degree cut: d runs along the slash (bottom-left -> top-right),
// n is its normal (the direction the halves separate).
let d = CGPoint(x: cos(CGFloat.pi / 4), y: sin(CGFloat.pi / 4))
let n = CGPoint(x: -d.y, y: d.x)

func p(_ a: CGPoint, _ s: CGFloat, _ b: CGPoint) -> CGPoint {
    CGPoint(x: a.x + s * b.x, y: a.y + s * b.y)
}

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                    bytesPerRow: 0, space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

// Night-sky indigo, darker toward the bottom — calm backdrop, monk palette.
let background = CGGradient(colorsSpace: colorSpace,
                            colors: [rgba(0.17, 0.19, 0.40), rgba(0.06, 0.08, 0.20)] as CFArray,
                            locations: [0, 1])!
ctx.drawLinearGradient(background,
                       start: CGPoint(x: 0, y: CGFloat(size)),
                       end: CGPoint(x: 0, y: 0), options: [])

/// Clip to one side of the cut line (sign picks the side), then draw the
/// disc shifted that way: apart along the normal (the gap) and along the cut
/// (the shear). The cut edge moves with its half, so the edges stay parallel,
/// 2*separation apart, while the arcs misalign — unmistakably two pieces.
func drawHalfDisc(side: CGFloat) {
    ctx.saveGState()
    let discCenter = p(p(center, side * separation, n), side * slide, d)
    let halfPlane = CGMutablePath()
    halfPlane.move(to: p(discCenter, -1500, d))
    halfPlane.addLine(to: p(discCenter, 1500, d))
    halfPlane.addLine(to: p(p(discCenter, 1500, d), side * 2000, n))
    halfPlane.addLine(to: p(p(discCenter, -1500, d), side * 2000, n))
    halfPlane.closeSubpath()
    ctx.addPath(halfPlane)
    ctx.clip()

    // Saffron disc, lit from the upper region: the sun / the ensō.
    let disc = CGGradient(colorsSpace: colorSpace,
                          colors: [rgba(1.00, 0.80, 0.42), rgba(0.93, 0.52, 0.10)] as CFArray,
                          locations: [0, 1])!
    let lightFrom = CGPoint(x: discCenter.x - 90, y: discCenter.y + 120)
    ctx.addEllipse(in: CGRect(x: discCenter.x - discRadius, y: discCenter.y - discRadius,
                              width: discRadius * 2, height: discRadius * 2))
    ctx.clip()
    ctx.drawRadialGradient(disc, startCenter: lightFrom, startRadius: 0,
                           endCenter: discCenter, endRadius: discRadius * 1.25, options: [])
    ctx.restoreGState()
}

drawHalfDisc(side: 1)
drawHalfDisc(side: -1)

/// The blade streak: a sharp-tipped lens along the cut. Drawn twice — a
/// broad faint pass for glow, then the bright edge.
func drawStreak(width: CGFloat, alpha: CGFloat) {
    let tip1 = p(center, -streakReach, d)
    let tip2 = p(center, streakReach, d)
    let streak = CGMutablePath()
    streak.move(to: tip1)
    streak.addQuadCurve(to: tip2, control: p(center, width, n))
    streak.addQuadCurve(to: tip1, control: p(center, -width, n))
    streak.closeSubpath()
    ctx.addPath(streak)
    ctx.setFillColor(rgba(1, 1, 1, alpha))
    ctx.fillPath()
}

drawStreak(width: streakWidth * 2.6, alpha: 0.22)
drawStreak(width: streakWidth, alpha: 0.96)

let image = ctx.makeImage()!
let outPath = (CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let url = URL(fileURLWithPath: outPath)
try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("failed to write \(outPath)") }
print("wrote \(outPath)")
