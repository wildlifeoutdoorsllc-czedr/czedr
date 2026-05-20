//
//  CzedrBrandLogo.swift
//  Same asset + sizing as sign-in (CzedrTheme).
//

import SwiftUI
import UIKit

enum CzedrLogoStyle {
    /// Sign-in screen — large logo matching legacy ViewController.
    case signIn
    /// Toolbar strip on logged-in screens.
    case toolbar
    /// In-page hero (home and inner screens).
    case hero
}

struct CzedrBrandLogoView: View {
    let style: CzedrLogoStyle

    private var logoSize: CGSize {
        let panelW = UIScreen.main.bounds.width
        switch style {
        case .signIn:
            return CzedrTheme.brandAuthLogoDisplaySize(
                forPanelWidth: panelW - 48,
                panelHeight: 360
            )
        case .toolbar:
            return CzedrTheme.brandAuthLogoCompactDisplaySize(forPanelWidth: panelW)
        case .hero:
            return CzedrTheme.brandAuthLogoDisplaySize(
                forPanelWidth: panelW - 32,
                panelHeight: 200
            )
        }
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
        .frame(height: max(logoSize.height, style == .toolbar ? 44 : 72))
    }
}
