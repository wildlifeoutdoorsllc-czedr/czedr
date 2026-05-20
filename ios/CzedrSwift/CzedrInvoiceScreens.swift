//
//  CzedrInvoiceScreens.swift
//  Send Invoice — request payment from someone who owes you.
//

import SwiftUI

// MARK: - Send Invoice

struct SendInvoiceScreen: View {
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @State private var debtorId = ""
    @State private var validatedName = ""
    @State private var amount = ""
    @State private var description = ""
    @State private var pin = ""

    var body: some View {
        LoggedInPageLayout(title: "Send Invoice", showBack: true, onMenu: { showMenu = true }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Request payment from someone who owes you.")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        TextField("Debtor Czedr ID", text: $debtorId)
                            .textFieldStyle(CzedrFieldStyle())
                            .autocapitalization(.allCharacters)
                        Button("VALIDATE") { validate() }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .background(CzedrPalette.redPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    if !validatedName.isEmpty {
                        Text(validatedName).font(.footnote).foregroundColor(CzedrPalette.balanceGreen)
                    }

                    TextField("Amount they owe ($)", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CzedrFieldStyle())

                    TextField("Description", text: $description)
                        .textFieldStyle(CzedrFieldStyle())

                    Text("ENTER YOUR CZEDR PIN")
                        .font(.caption.bold())
                        .foregroundColor(CzedrPalette.redPrimary)
                        .padding(.top, 8)

                    SecureField("4-digit PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CzedrFieldStyle())

                    Button(action: sendInvoice) {
                        Text(session.isLoading ? "…" : "SEND INVOICE")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                    .disabled(session.isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func validate() {
        session.clearError()
        session.validateRecipient(debtorId) { name in
            validatedName = name ?? ""
        }
    }

    private func sendInvoice() {
        session.clearError()
        session.sendInvoice(
            to: debtorId,
            amountDollars: amount,
            description: description,
            pin: pin
        )
    }
}
