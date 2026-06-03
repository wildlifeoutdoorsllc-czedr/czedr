//
//  CzedrSupportViews.swift
//  In-app help for common support topics (contact, PIN recovery guidance).
//

import SwiftUI

enum CzedrSupport {
    static let email = "support@czedr.com"
}

struct CzedrSupportHelpCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Help")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
            Text("Forgot your payment PIN? Sign out, use Forgot password? on the sign-in screen, then open Change PIN from the menu.")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: URL(string: "mailto:\(CzedrSupport.email)?subject=Czedr%20app%20help")!) {
                HStack {
                    Image(systemName: "envelope")
                    Text("Email \(CzedrSupport.email)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(CzedrPalette.cheddarGold)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
