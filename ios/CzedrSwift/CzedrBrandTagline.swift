//
//  CzedrBrandTagline.swift
//  Brand voice under the logo — Cheddar wordplay stays in copy, not the mark.
//

import SwiftUI

struct CzedrBrandTaglineView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Never give your credit or debit card information again.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(CzedrPalette.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Cheddar, Stack it!")
                .font(.title3.weight(.bold))
                .foregroundColor(CzedrPalette.cheddarGold)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Cheddar, Stack it!")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}
