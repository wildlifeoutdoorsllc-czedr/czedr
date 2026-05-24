//
//  CzedrPinScreens.swift
//  Set / change account PIN (required before payments).
//

import SwiftUI

struct SetPinScreen: View {
    @EnvironmentObject var session: AppSession
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var localMessage = ""

    var body: some View {
        LoggedInPageLayout(title: session.hasPinSet ? "Change PIN" : "Set PIN", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(session.hasPinSet
                         ? "Enter a new 4-digit PIN for payments."
                         : "Create a 4-digit PIN. You will enter this when sending money or invoices.")
                        .font(.footnote)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("NEW PIN")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.redPrimary)
                    CzedrPinEntryView(pin: $pin, label: "ENTER NEW PIN")

                    Text("CONFIRM PIN")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.redPrimary)
                    CzedrPinEntryView(pin: $confirmPin, label: "CONFIRM NEW PIN")

                    if !localMessage.isEmpty {
                        Text(localMessage)
                            .font(.footnote)
                            .foregroundColor(CzedrPalette.balanceGreen)
                    }
                    if let err = session.errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(CzedrPalette.redPrimary)
                    }

                    Button(action: save) {
                        Text(session.isLoading ? "…" : "SAVE PIN")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                    .disabled(session.isLoading)
                }
                .padding(16)
            }
        }
    }

    private func save() {
        session.clearError()
        localMessage = ""
        guard pin.count == 4, confirmPin.count == 4 else {
            session.errorMessage = "PIN must be 4 digits"
            return
        }
        guard pin == confirmPin else {
            session.errorMessage = "PINs do not match"
            return
        }
        CzedrKeyboard.dismiss()
        session.setAccountPin(pin) {
            localMessage = "PIN saved. You can send payments now."
            pin = ""
            confirmPin = ""
        }
    }
}
