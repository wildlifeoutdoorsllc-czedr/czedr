//
//  CzedrSupportViews.swift
//  In-app help for common support topics (contact, PIN recovery guidance).
//

import SwiftUI

enum CzedrSupport {
    /// Member support inbox (must stay in sync with marketing/site-config.json).
    static let email = "support@czedr.com"

    /// Public privacy policy (App Store, sign-up, Profile).
    static let privacyPolicyURL = URL(string: "https://czedr.com/privacy")!

    static var mailtoURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: "Czedr app help")]
        return components.url ?? URL(string: "mailto:\(email)")!
    }
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
            Text("Member support")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
                .padding(.top, 4)
            Text(CzedrSupport.email)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(CzedrPalette.lightText)
            Link(destination: CzedrSupport.mailtoURL) {
                HStack {
                    Image(systemName: "envelope")
                    Text("Email support")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(CzedrPalette.cheddarGold)
            }
            Link(destination: CzedrSupport.privacyPolicyURL) {
                HStack {
                    Image(systemName: "hand.raised")
                    Text("Privacy Policy")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(CzedrPalette.cheddarGold)
            }
        }
        .padding(.vertical, 8)
    }
}
