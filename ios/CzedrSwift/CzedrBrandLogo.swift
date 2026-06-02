//
//  CzedrBrandLogo.swift
//  Same asset as sign-in; hero uses large in-page sizing (matches legacy prominence).
//

import SwiftUI
import UIKit

enum CzedrLogoStyle {
    /// Sign-in screen — full-width logo.
    case signIn
    /// Toolbar strip (unused on current screens; kept for flexibility).
    case toolbar
    /// Logged-in pages — large logo below toolbar (same visual weight as sign-in).
    case hero
    /// Profile and other dense screens — smaller hero so toolbar and content stay on screen.
    case heroCompact
}

struct CzedrBrandLogoView: View {
    let style: CzedrLogoStyle

    private var logoSize: CGSize {
        let panelW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        let image = CzedrTheme.brandAuthLogoImage()
        guard image.size.width > 0, image.size.height > 0 else {
            return CGSize(width: panelW - 48, height: 120)
        }
        let aspect = image.size.width / image.size.height

        switch style {
        case .signIn:
            return Self.fitLogo(
                aspect: aspect,
                maxWidth: panelW - 40,
                maxHeight: min(screenH * 0.38, 420)
            )
        case .hero:
            // ~5–6× larger than the old 200pt panel cap (~52px tall).
            return Self.fitLogo(
                aspect: aspect,
                maxWidth: panelW - 24,
                maxHeight: min(screenH * 0.32, 380)
            )
        case .heroCompact:
            return Self.fitLogo(
                aspect: aspect,
                maxWidth: panelW - 48,
                maxHeight: min(screenH * 0.14, 100)
            )
        case .toolbar:
            return CzedrTheme.brandAuthLogoCompactDisplaySize(forPanelWidth: panelW)
        }
    }

    private static func fitLogo(aspect: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        var height = min(maxHeight, maxWidth / max(aspect, 0.5))
        var width = height * aspect
        if width > maxWidth {
            width = maxWidth
            height = width / max(aspect, 0.5)
        }
        return CGSize(width: width, height: height)
    }

    var body: some View {
        Group {
            let image = CzedrTheme.brandAuthLogoImage()
            if image.size.width > 0, image.size.height > 0, logoSize.width > 1, logoSize.height > 1 {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize.width, height: logoSize.height)
                    .accessibilityLabel("Czedr")
            } else {
                Text("Czedr")
                    .font(style == .signIn ? .title.bold() : .headline)
                    .foregroundColor(CzedrPalette.lightText)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight)
    }

    private var containerHeight: CGFloat {
        switch style {
        case .toolbar:
            return max(logoSize.height, 44)
        case .signIn, .hero, .heroCompact:
            return logoSize.height + 12
        }
    }
}
