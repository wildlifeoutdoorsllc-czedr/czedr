//
//  CzedrReferralScreens.swift
//  Referral earnings from referee payments (single-level referrals).
//

import SwiftUI

struct ReferralEarningsScreen: View {
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @Environment(\.czedrTextSize) private var textSize
    @State private var earnings: ReferralEarnings?
    @State private var screenError: String?
    @State private var isLoading = false

    var body: some View {
        LoggedInPageLayout(title: "Referral Earnings", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("You earn a small reward when people you referred make payments on Czedr. Credits are already in your balance.")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    if isLoading && earnings == nil {
                        Text("Loading…")
                            .foregroundColor(CzedrPalette.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else if let err = screenError, earnings == nil {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(CzedrPalette.redPrimary)
                    } else if let data = earnings {
                        VStack(spacing: 8) {
                            Text("Total from referrals")
                                .font(.caption)
                                .foregroundColor(CzedrPalette.caption)
                            Text(CzedrMoney.format(cents: data.totalCents, currency: data.currency))
                                .font(.system(size: CzedrTypography.scaled(34, size: textSize), weight: .semibold))
                                .foregroundColor(CzedrPalette.balanceGreen)
                            Text("\(data.paymentCount) qualifying referee payment\(data.paymentCount == 1 ? "" : "s")")
                                .font(.footnote)
                                .foregroundColor(CzedrPalette.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        if data.recent.isEmpty {
                            Text("No referral credits yet. Share your Czedr ID when someone signs up.")
                                .font(.subheadline)
                                .foregroundColor(CzedrPalette.caption)
                                .padding(.top, 8)
                        } else {
                            Text("Recent credits")
                                .font(.caption.bold())
                                .foregroundColor(CzedrPalette.lightText)
                                .padding(.top, 8)

                            ForEach(data.recent) { credit in
                                referralCreditRow(credit, currency: data.currency)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .onAppear(perform: load)
    }

    private func referralCreditRow(_ credit: ReferralCredit, currency: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(CzedrMoney.signedFormat(cents: credit.amountCents, isCredit: true, currency: currency))
                .font(.headline)
                .foregroundColor(CzedrPalette.balanceGreen)
            if !credit.memo.isEmpty {
                Text(credit.memo)
                    .font(.subheadline)
                    .foregroundColor(CzedrPalette.lightText)
            }
            if !credit.createdAt.isEmpty {
                Text(credit.createdAt)
                    .font(.caption)
                    .foregroundColor(CzedrPalette.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CzedrPalette.surface)
        .cornerRadius(8)
    }

    private func load() {
        screenError = nil
        isLoading = true
        session.fetchReferralEarnings { result in
            isLoading = false
            switch result {
            case .success(let data):
                earnings = data
            case .failure(let msg):
                screenError = msg
            }
        }
    }
}
