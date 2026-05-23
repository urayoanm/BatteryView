//
//  BatteryViewSUI.swift
//
//  SwiftUI implementation of BatteryView.
//  For the UIKit version import BatteryView instead.
//

import SwiftUI

// MARK: - Direction

/// Direction the battery terminal points toward.
public enum BatteryDirection {
    case up, down, left, right

    var isVertical: Bool { self == .up || self == .down }
}

// MARK: - BatteryView

/// SwiftUI battery indicator. Charged `level` percent, oriented toward `direction`.
/// Turns red when level drops below `lowThreshold`, or gradually when below `gradientThreshold`.
public struct BatteryView: View {

    // MARK: Properties

    /// 0 to 100 percent full. Pass -1 for unavailable.
    public var level: Int

    /// Color switches to `lowLevelColor` below this threshold.
    public var lowThreshold: Int

    /// Color starts blending toward `lowLevelColor` below this threshold.
    public var gradientThreshold: Int

    /// Which edge the terminal nub appears on.
    public var direction: BatteryDirection

    /// Terminal length as a fraction of total view length.
    public var terminalLengthRatio: CGFloat

    /// Terminal width as a fraction of body width.
    public var terminalWidthRatio: CGFloat

    public var highLevelColor: Color
    public var lowLevelColor: Color
    public var noLevelColor: Color
    public var borderColor: Color

    /// Pass 0 to auto-size to length / 20.
    public var borderWidth: CGFloat

    /// Pass 0 to auto-size to length / 10.
    public var cornerRadius: CGFloat

    /// Shown centered on the body when level is undefined or out of range.
    public var noLevelText: String

    public init(
        level: Int = -1,
        lowThreshold: Int = 10,
        gradientThreshold: Int = 0,
        direction: BatteryDirection = .up,
        terminalLengthRatio: CGFloat = 0.1,
        terminalWidthRatio: CGFloat = 0.4,
        highLevelColor: Color = Color(red: 0.0, green: 0.9, blue: 0.0),
        lowLevelColor: Color = Color(red: 0.9, green: 0.0, blue: 0.0),
        noLevelColor: Color = Color(white: 0.8),
        borderColor: Color = .primary,
        borderWidth: CGFloat = 0,
        cornerRadius: CGFloat = 0,
        noLevelText: String = "?"
    ) {
        self.level = level
        self.lowThreshold = lowThreshold
        self.gradientThreshold = gradientThreshold
        self.direction = direction
        self.terminalLengthRatio = terminalLengthRatio
        self.terminalWidthRatio = terminalWidthRatio
        self.highLevelColor = highLevelColor
        self.lowLevelColor = lowLevelColor
        self.noLevelColor = noLevelColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.noLevelText = noLevelText
    }

    // MARK: Body

    public var body: some View {
        GeometryReader { geo in
            let isVertical = direction.isVertical
            let length: CGFloat = isVertical ? geo.size.height : geo.size.width
            let resolvedBorder: CGFloat = borderWidth > 0 ? borderWidth : length / 20
            let resolvedRadius: CGFloat = cornerRadius > 0 ? cornerRadius : length / 10
            let terminalLength = terminalLengthRatio * length

            ZStack {
                _BatteryShape(
                    direction: direction,
                    terminalLengthRatio: terminalLengthRatio,
                    terminalWidthRatio: terminalWidthRatio,
                    borderWidth: resolvedBorder,
                    cornerRadius: resolvedRadius,
                    fillFraction: levelFraction,
                    fillColor: currentFillColor,
                    noLevelColor: noLevelColor,
                    isFullyCharged: level == 100
                )
                .foregroundColor(borderColor)

                if !isValidLevel {
                    let bodyLength = length - terminalLength
                    let bodyWidth: CGFloat = isVertical ? geo.size.width : geo.size.height
                    let fontSize = min(bodyWidth, bodyLength * 0.75)
                    Text(noLevelText)
                        .font(.system(size: fontSize))
                        .foregroundColor(.primary)
                        .offset(noLevelOffset(terminalLength: terminalLength))
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("battery")
        .accessibilityValue(isValidLevel ? "\(level)" : noLevelText)
    }

    // MARK: Helpers

    private var isValidLevel: Bool { level >= 0 && level <= 100 }

    private var levelFraction: CGFloat {
        guard isValidLevel else { return -1 }
        return CGFloat(level) / 100
    }

    var currentFillColor: Color {
        guard isValidLevel else { return noLevelColor }
        if level <= lowThreshold { return lowLevelColor }
        if gradientThreshold == 0 || level >= gradientThreshold { return highLevelColor }
        let range = CGFloat(gradientThreshold - lowThreshold)
        let fraction = range > 0 ? CGFloat(level - lowThreshold) / range : 1
        return lowLevelColor.blended(with: highLevelColor, fraction: fraction)
    }

    private func noLevelOffset(terminalLength: CGFloat) -> CGSize {
        switch direction {
        case .up:    return CGSize(width: 0, height: terminalLength / 2)
        case .down:  return CGSize(width: 0, height: -terminalLength / 2)
        case .left:  return CGSize(width: terminalLength / 2, height: 0)
        case .right: return CGSize(width: -terminalLength / 2, height: 0)
        }
    }
}

// MARK: - Canvas shape

private struct _BatteryShape: View {
    var direction: BatteryDirection
    var terminalLengthRatio: CGFloat
    var terminalWidthRatio: CGFloat
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var fillFraction: CGFloat   // -1 = no level
    var fillColor: Color
    var noLevelColor: Color
    var isFullyCharged: Bool

    var body: some View {
        Canvas { ctx, size in
            let isVertical = direction.isVertical
            let length: CGFloat = isVertical ? size.height : size.width
            let crossLength: CGFloat = isVertical ? size.width : size.height
            let terminalLen = terminalLengthRatio * length
            let terminalCross = terminalWidthRatio * crossLength
            let terminalSideInset = (crossLength - terminalCross) / 2

            // Rects for body and terminal
            let bodyRect: CGRect
            let terminalRect: CGRect
            switch direction {
            case .up:
                bodyRect    = CGRect(x: 0, y: terminalLen, width: size.width, height: size.height - terminalLen)
                terminalRect = CGRect(x: terminalSideInset, y: 0, width: terminalCross, height: terminalLen + borderWidth)
            case .down:
                bodyRect    = CGRect(x: 0, y: 0, width: size.width, height: size.height - terminalLen)
                terminalRect = CGRect(x: terminalSideInset, y: size.height - terminalLen - borderWidth, width: terminalCross, height: terminalLen + borderWidth)
            case .left:
                bodyRect    = CGRect(x: terminalLen, y: 0, width: size.width - terminalLen, height: size.height)
                terminalRect = CGRect(x: 0, y: terminalSideInset, width: terminalLen + borderWidth, height: terminalCross)
            case .right:
                bodyRect    = CGRect(x: 0, y: 0, width: size.width - terminalLen, height: size.height)
                terminalRect = CGRect(x: size.width - terminalLen - borderWidth, y: terminalSideInset, width: terminalLen + borderWidth, height: terminalCross)
            }

            let bodyRadius = cornerRadius
            let terminalRadius = cornerRadius / 2
            let innerBody = bodyRect.insetBy(dx: borderWidth, dy: borderWidth)

            // Fill
            let fillRect = fillFraction >= 0 ? levelFillRect(in: innerBody) : innerBody
            let fillPaint: GraphicsContext.Shading = fillFraction >= 0
                ? .color(fillColor)
                : .color(noLevelColor)
            ctx.fill(
                Path(roundedRect: fillRect, cornerRadius: max(0, bodyRadius - borderWidth)),
                with: fillPaint
            )

            // Body stroke
            ctx.stroke(
                Path(roundedRect: bodyRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: bodyRadius),
                with: .foreground,
                lineWidth: borderWidth
            )

            // Terminal (filled with charge color when full, else noLevelColor)
            ctx.fill(
                Path(roundedRect: terminalRect, cornerRadius: terminalRadius),
                with: .color(isFullyCharged ? fillColor : noLevelColor)
            )
            ctx.stroke(
                Path(roundedRect: terminalRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: terminalRadius),
                with: .foreground,
                lineWidth: borderWidth
            )
        }
    }

    private func levelFillRect(in rect: CGRect) -> CGRect {
        guard fillFraction >= 0 else { return rect }
        switch direction {
        case .up:
            let h = rect.height * fillFraction
            return CGRect(x: rect.minX, y: rect.maxY - h, width: rect.width, height: h)
        case .down:
            let h = rect.height * fillFraction
            return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h)
        case .left:
            let w = rect.width * fillFraction
            return CGRect(x: rect.maxX - w, y: rect.minY, width: w, height: rect.height)
        case .right:
            let w = rect.width * fillFraction
            return CGRect(x: rect.minX, y: rect.minY, width: w, height: rect.height)
        }
    }
}

// MARK: - Color blending

extension Color {
    func blended(with other: Color, fraction: CGFloat) -> Color {
        let f = min(1, max(0, fraction))
#if canImport(UIKit)
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        UIColor(other).getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        return Color(UIColor(
            hue: h1 + (h2 - h1) * f,
            saturation: s1 + (s2 - s1) * f,
            brightness: b1 + (b2 - b1) * f,
            alpha: a1 + (a2 - a1) * f
        ))
#elseif canImport(AppKit)
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        NSColor(self).getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        NSColor(other).getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        return Color(NSColor(
            hue: h1 + (h2 - h1) * f,
            saturation: s1 + (s2 - s1) * f,
            brightness: b1 + (b2 - b1) * f,
            alpha: a1 + (a2 - a1) * f
        ))
#else
        return fraction < 0.5 ? self : other
#endif
    }
}

// MARK: - Previews

struct BatteryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BatteryView(level: 100)
                .frame(width: 40, height: 80)

            BatteryView(level: 5, lowThreshold: 10)
                .frame(width: 40, height: 80)

            BatteryView(level: 30, lowThreshold: 10, gradientThreshold: 50)
                .frame(width: 40, height: 80)

            BatteryView(level: -1)
                .frame(width: 40, height: 80)

            BatteryView(level: 60, direction: .right)
                .frame(width: 100, height: 40)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
