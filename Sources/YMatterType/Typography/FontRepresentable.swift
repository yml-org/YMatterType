//
//  FontRepresentable.swift
//  YMatterType
//
//  Created by Mark Pospesel on 8/23/21.
//  Copyright © 2021 Y Media Labs. All rights reserved.
//

import UIKit
import os

/// Information about a font family. When an app specifies a custom font, they will
/// implement an instance of FontRepresentable to fully describe that font.
public protocol FontRepresentable {
    /// Font family root name, e.g. "AvenirNext"
    var familyName: String { get }
    
    /// Optional suffix to use for the font name.
    ///
    /// Used by `FontRepresentable.fontName(for:compatibleWith:)`
    /// e.g. "Italic" is a typical suffix for italic fonts.
    /// default = ""
    var fontNameSuffix: String { get }
    
    // The following four methods have default implementations that
    // can be overridden in custom implementations of FontRepresentable
    
    /// Returns a font for the specified `weight` and `pointSize` that is compatible with the `traitCollection`
    /// - Parameters:
    ///   - weight: desired font weight
    ///   - pointSize: desired font point size
    ///   - traitCollection: trait collection to consider (`UITraitCollection.legibilityWeight`).
    /// If `nil` then `UIAccessibility.isBoldTextEnabled` will be considered instead
    func font(
        for weight: Typography.FontWeight,
        pointSize: CGFloat,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIFont

    /// Generates a font name that can be used to initialize a `UIFont`. Not all fonts support all 9 weights.
    /// - Parameter weight: desired font weight
    /// - Parameter traitCollection: trait collection to consider (`UITraitCollection.legibilityWeight`).
    /// If `nil` then `UIAccessibility.isBoldTextEnabled` will be considered instead
    /// - Returns: The font name formulated from `familyName` and `weight`
    func fontName(for weight: Typography.FontWeight, compatibleWith traitCollection: UITraitCollection?) -> String
    
    /// Generates a weight name suffix as part of a full font name. Not all fonts support all 9 weights.
    /// - Parameter weight: desired font weight
    /// - Returns: The weight name to use
    func weightName(for weight: Typography.FontWeight) -> String
    
    /// Returns the alternate weight to use if user has requested a bold font. e.g. might convert `.regular`
    /// to `.semibold`. Not all fonts support all 9 weights.
    /// - Parameter weight: desired font weight
    /// - Returns: the alternate weight to use if user has requested a bold font.
    /// Should be heavier than weight if possible.
    func accessibilityBoldWeight(for weight: Typography.FontWeight) -> Typography.FontWeight
}

extension Typography {
    fileprivate static let logger = Logger(subsystem: "YMatterType", category: "fonts")
}

// MARK: - Default implementations

extension FontRepresentable {
    public var fontNameSuffix: String { "" }

    public func font(
        for weight: Typography.FontWeight,
        pointSize: CGFloat,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIFont {
        let name = fontName(for: weight, compatibleWith: traitCollection)
        guard let font = UIFont(name: name, size: pointSize) else {
            // Fallback to system font and log a message.
            Typography.logger.warning("Custom font \(name) not properly installed.")
            return FontInfo.system.font(
                for: weight,
                pointSize: pointSize,
                compatibleWith: traitCollection
            )
        }
        return font
    }
    
    public func fontName(
        for weight: Typography.FontWeight,
        compatibleWith traitCollection: UITraitCollection?
    ) -> String {
        // Default font name formulation accounting for Accessibility Bold setting
        let useBoldFont = isBoldTextEnabled(compatibleWith: traitCollection)
        let actualWeight = useBoldFont ? accessibilityBoldWeight(for: weight) : weight
        let weightName = weightName(for: actualWeight)
        return "\(familyName)-\(weightName)\(fontNameSuffix)"
    }
    
    public func weightName(for weight: Typography.FontWeight) -> String {
        // Default font name suffix by weight
        switch weight {
        case .ultralight:
            return "ExtraLight"
        case .thin:
            return "Thin"
        case .light:
            return "Light"
        case .regular:
            return "Regular"
        case .medium:
            return "Medium"
        case .semibold:
            return "SemiBold"
        case .bold:
            return "Bold"
        case .heavy:
            return "ExtraBold"
        case .black:
            return "Black"
        }
    }
    
    public func accessibilityBoldWeight(for weight: Typography.FontWeight) -> Typography.FontWeight {
        // By default we will move up 1 weight when Accessibility Bold is enabled
        // (Override to transform to different weights or only to those weighs available for a specific font family.)
        switch weight {
        case .ultralight:
            return .thin
        case .thin:
            return .light
        case .light:
            return .regular
        case .regular:
            return .medium
        case .medium:
            return .semibold
        case .semibold:
            return .bold
        case .bold:
            return .heavy
        case .heavy, .black:
            return .black
        }
    }

    /// Determines whether the accessibility Bold Text feature is enabled within the given trait collection.
    /// - Parameter traitCollection: the trait collection to evaluate (or nil to use system settings)
    /// - Returns: `true` if the accessibility Bold Text feature is enabled.
    ///
    /// If `traitCollection` is not `nil`, it checks for `legibilityWeight == .bold`.
    /// If `traitCollection` is `nil`, then it examines the system wide `UIAccessibility` setting of the same name.
    public func isBoldTextEnabled(compatibleWith traitCollection: UITraitCollection?) -> Bool {
        guard let traitCollection = traitCollection else {
            return UIAccessibility.isBoldTextEnabled
        }
        
        return traitCollection.legibilityWeight == .bold
    }
}
