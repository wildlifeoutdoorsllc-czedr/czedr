//
//  CzedrPaymentSuccess.swift
//  Make Payment confirmation screen.
//

import SwiftUI

struct PaymentSuccessDetails: Equatable {
    let transactionId: String?
    let recipientCzedrId: String
    let recipientName: String
    let amountCents: Int64
    let memo: String
}

struct PaymentSuccessScreen: View {
    @EnvironmentObject var session: AppSession
    let details: PaymentSuccessDetails
    @Binding var isPresented: Bool
    var onDone: () -> Void

    var body: some View {
        LoggedInPageLayout(title: "Success", showBack: false, onMenu: { session.presentMenu() }) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(CzedrPalette.balanceGreen)
                    .padding(.top, 24)

                Text("Payment is successful")
                    .font(.title2.bold())
                    .foregroundColor(CzedrPalette.lightText)
                    .multilineTextAlignment(.center)

                Text(CzedrMoney.format(cents: details.amountCents))
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(CzedrPalette.balanceGreen)

                VStack(alignment: .leading, spacing: 10) {
                    successRow("To", recipientLine)
                    if !details.memo.isEmpty {
                        successRow("Description", details.memo)
                    }
                    if let txnId = details.transactionId, !txnId.isEmpty {
                        successRow("Transaction ID", txnId)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(CzedrPalette.surface)
                .cornerRadius(8)

                Spacer(minLength: 12)

                Button(action: finish) {
                    Text("OK")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CzedrPalette.charcoalButton)
                        .foregroundColor(CzedrPalette.lightText)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var recipientLine: String {
        let id = details.recipientCzedrId.uppercased()
        if details.recipientName.isEmpty || details.recipientName.uppercased() == id {
            return id
        }
        return "\(details.recipientName) (\(id))"
    }

    private func successRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
            Text(value)
                .font(.subheadline)
                .foregroundColor(CzedrPalette.lightText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func finish() {
        isPresented = false
        onDone()
    }
}
