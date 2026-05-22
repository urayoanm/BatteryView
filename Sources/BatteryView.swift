//
//  BatteryView.swift
//
//  Created by Yonat Sharon on 6/1/15.
//  Copyright (c) 2015-6 Yonat Sharon. All rights reserved.
//

import SwiftUI

public extension Int {
    static let fullBattery = 100
}

// MARK: - Direction

public enum BatteryDirection {
    case up, down, left, right

    var isVertical: Bool { self == .up || self == .down }
}

// MARK: - BatteryView

/// Show a battery oriented toward `direction`, charged `level` percent.
/// Turns red when level drops below `lowThreshold`, or gradually when below `gradientThreshold`.
public struct BatteryView: View {
    // MARK: - Properties

    /// 0 to 100 percent full, unavailable = -1
    public var level: Int

    /// Change color when level crosses this threshold
    public var lowThreshold: Int

    /// Gradually change color when level crosses this threshold
    public var gradientThreshold: Int

    /// Direction of battery terminal
    public var direction: BatteryDirection

    /// Relative length of battery terminal
    public var terminalLengthRatio: CGFloat

    /// Relative width of battery terminal
    public var terminalWidthRatio: CGFloat

    public var highLevelColor: Color
    public var lowLevelColor: Color
    public var noLevelColor: Color
    public var borderColor: Color

    /// 0 = auto (length / 20)
    public var borderWidth: CGFloat

    /// 0 = auto (length / 10)
    public var cornerRadius: CGFloat

    /// Label shown when level is undefined or out of range
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
        borderColor: Color = Color.primary,
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

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let isVertical = direction.isVertical
            let length: CGFloat = isVertical ? geo.size.height : geo.size.width
            let resolvedBorderWidth: CGFloat = borderWidth > 0 ? borderWidth : length / 20
            let resolvedCornerRadius: CGFloat = cornerRadius > 0 ? cornerRadius : length / 10
            let terminalLength = terminalLengthRatio * length

            ZStack {
                BatteryShape(
                    direction: direction,
                    terminalLengthRatio: terminalLengthRatio,
                    terminalWidthRatio: terminalWidthRatio,
                    borderWidth: resolvedBorderWidth,
                    cornerRadius: resolvedCornerRadius,
                    fillFraction: levelFraction,
                    fillColor: currentFillColor,
                    noLevelColor: noLevelColor,
                    isFullyCharged: level == .fullBattery
                )
                .foregroundColor(borderColor)

                if !isValidLevel {
                    let bodyLength = length - terminalLength
                    let bodySize: CGSize = isVertical
                        ? CGSize(width: geo.size.width, height: bodyLength)
                        : CGSize(width: bodyLength, height: geo.size.height)
                    let fontSize = min(bodySize.width, bodySize.height * 0.75)

                    Text(noLevelText)
                        .font(.system(size: fontSize))
                        .foregroundColor(Color.primary)
                        .offset(terminalOffset(terminalLength: terminalLength, isVertical: isVertical))
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("battery")
        .accessibilityValue(isValidLevel ? "\(level)" : noLevelText)
    }

    // MARK: - Helpers

    private var isValidLevel: Bool { level >= 0 && level <= .fullBattery }

    private var levelFraction: CGFloat {
        guard isValidLevel else { return -1 }
        return CGFloat(level) / CGFloat(Int.fullBattery)
    }

    var currentFillColor: Color {
        guard isValidLevel else { return noLevelColor }
        switch level {
        case 0 ... lowThreshold:
            return lowLevelColor
        case gradientThreshold ... .fullBattery:
            return highLevelColor
        default:
            let range = CGFloat(max(gradientThreshold, lowThreshold + 1) - lowThreshold)
            let fraction = range > 0 ? CGFloat(level - lowThreshold) / range : 1
            return lowLevelColor.blend(with: highLevelColor, fraction: fraction)
        }
    }

    private func terminalOffset(terminalLength: CGFloat, isVertical: Bool) -> CGSize {
        switch direction {
        case .up:    return CGSize(width: 0, height: terminalLength / 2)
        case .down:  return CGSize(width: 0, height: -terminalLength / 2)
        case .left:  return CGSize(width: terminalLength / 2, height: 0)
        case .right: return CGSize(width: -terminalLength / 2, height: 0)
        }
    }
}

// MARK: - BatteryShape

private struct BatteryShape: View {
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
        Canvas { context, size in
            let isVertical = direction.isVertical
            let length: CGFloat = isVertical ? size.height : size.width
            let terminalLength = terminalLengthRatio * length
            let terminalWidth = terminalWidthRatio * (isVertical ? size.width : size.height)
            let terminalSideInset = ((isVertical ? size.width : size.height) - terminalWidth) / 2

            // Body rect
            let bodyRect: CGRect
            let terminalRect: CGRect
            switch direction {
            case .up:
                bodyRect = CGRect(x: 0, y: terminalLength, width: size.width, height: size.height - terminalLength)
                terminalRect = CGRect(x: terminalSideInset, y: 0, width: terminalWidth, height: terminalLength + borderWidth)
            case .down:
                bodyRect = CGRect(x: 0, y: 0, width: size.width, height: size.height - terminalLength)
                terminalRect = CGRect(x: terminalSideInset, y: size.height - terminalLength - borderWidth, width: terminalWidth, height: terminalLength + borderWidth)
            case .left:
                bodyRect = CGRect(x: terminalLength, y: 0, width: size.width - terminalLength, height: size.height)
                terminalRect = CGRect(x: 0, y: terminalSideInset, width: terminalLength + borderWidth, height: terminalWidth)
            case .right:
                bodyRect = CGRect(x: 0, y: 0, width: size.width - terminalLength, height: size.height)
                terminalRect = CGRect(x: size.width - terminalLength - borderWidth, y: terminalSideInset, width: terminalLength + borderWidth, height: terminalWidth)
            }

            let bodyRadius = cornerRadius
            let terminalRadius = cornerRadius / 2

            // Draw fill inside body
            let fillInset = borderWidth
            let innerBody = bodyRect.insetBy(dx: fillInset, dy: fillInset)
            let fillRect = fillArea(in: innerBody, fraction: fillFraction)

            if fillFraction >= 0 {
                context.fill(Path(roundedRect: fillRect, cornerRadius: max(0, bodyRadius - fillInset)), with: .color(fillColor))
            } else {
                context.fill(Path(roundedRect: innerBody, cornerRadius: max(0, bodyRadius - fillInset)), with: .color(noLevelColor))
            }

            // Draw body outline (stroke)
            context.stroke(
                Path(roundedRect: bodyRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: bodyRadius),
                with: .foreground,
                lineWidth: borderWidth
            )

            // Terminal fill (full charge propagates color into terminal)
            let terminalFillColor: Color = isFullyCharged ? fillColor : noLevelColor
            context.fill(Path(roundedRect: terminalRect, cornerRadius: terminalRadius), with: .color(terminalFillColor))

            // Draw terminal outline (stroke)
            context.stroke(
                Path(roundedRect: terminalRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: terminalRadius),
                with: .foreground,
                lineWidth: borderWidth
            )
        }
    }

    private func fillArea(in rect: CGRect, fraction: CGFloat) -> CGRect {
        guard fraction >= 0 else { return rect }
        switch direction {
        case .up:
            let h = rect.height * fraction
            return CGRect(x: rect.minX, y: rect.maxY - h, width: rect.width, height: h)
        case .down:
            let h = rect.height * fraction
            return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h)
        case .left:
            let w = rect.width * fraction
            return CGRect(x: rect.maxX - w, y: rect.minY, width: w, height: rect.height)
        case .right:
            let w = rect.width * fraction
            return CGRect(x: rect.minX, y: rect.minY, width: w, height: rect.height)
        }
    }
}

// MARK: - Color Blending

extension Color {
    func blend(with other: Color, fraction: CGFloat) -> Color {
        let f = min(1, max(0, fraction))
        let c1 = UIColor(self)
        let c2 = UIColor(other)
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        c2.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        return Color(UIColor(
            hue: h1 + (h2 - h1) * f,
            saturation: s1 + (s2 - s1) * f,
            brightness: b1 + (b2 - b1) * f,
            alpha: a1 + (a2 - a1) * f
        ))
    }
}

// MARK: - Previews

struct BatteryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Full
            BatteryView(level: 100)
                .frame(width: 40, height: 80)

            // Low
            BatteryView(level: 5, lowThreshold: 10)
                .frame(width: 40, height: 80)

            // Gradient mid-range
            BatteryView(level: 30, lowThreshold: 10, gradientThreshold: 50)
                .frame(width: 40, height: 80)

            // No level
            BatteryView(level: -1)
                .frame(width: 40, height: 80)

            // Horizontal
            BatteryView(level: 60, direction: .right)
                .frame(width: 100, height: 40)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
