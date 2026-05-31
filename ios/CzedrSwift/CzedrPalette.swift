//
//  CzedrPalette.swift
//  Matches legacy CzedrTheme colors for a consistent look.
//

import SwiftUI

enum CzedrPalette {
    static let background = Color(red: 42 / 255, green: 42 / 255, blue: 44 / 255)
    static let surface = Color(red: 53 / 255, green: 53 / 255, blue: 56 / 255)
    static let orangeField = Color(red: 245 / 255, green: 130 / 255, blue: 32 / 255)
    static let redPrimary = Color(red: 227 / 255, green: 30 / 255, blue: 36 / 255)
    static let charcoalButton = Color(red: 88 / 255, green: 89 / 255, blue: 91 / 255)
    static let gridTile = Color(red: 201 / 255, green: 74 / 255, blue: 31 / 255)
    static let lightText = Color(red: 231 / 255, green: 236 / 255, blue: 243 / 255)
    static let caption = Color(red: 176 / 255, green: 181 / 255, blue: 188 / 255)
    static let balanceGreen = Color(red: 50 / 255, green: 205 / 255, blue: 90 / 255)
    /// Cheddar tagline accent — warm gold (money / cheese nod).
    static let cheddarGold = Color(red: 255 / 255, green: 196 / 255, blue: 46 / 255)
    /// Typed text on orange inputs — dark for strong contrast on #F58220.
    static let fieldText = Color.black
    /// Hint text on orange inputs (slightly softer than typed text).
    static let fieldPlaceholder = Color.black.opacity(0.5)
}
