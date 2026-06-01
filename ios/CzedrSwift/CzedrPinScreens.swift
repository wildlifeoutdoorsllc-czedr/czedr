//
//  CzedrPinScreens.swift
//  Set / change account PIN (required before payments).
//

import SwiftUI

struct SetPinScreen: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.presentationMode) private var presentationMode
    @State private var step = 1
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

                    if step == 1 {
                        Text("STEP 1 OF 2 — NEW PIN")
                            .font(.caption)
                            .foregroundColor(CzedrPalette.redPrimary)
                        CzedrPinEntryView(pin: $pin, label: "ENTER NEW PIN", fieldId: 1)

                        Button(action: goToConfirmStep) {
                            Text("NEXT")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(CzedrPalette.charcoalButton)
                                .foregroundColor(CzedrPalette.lightText)
                                .cornerRadius(6)
                        }
                        .disabled(pin.count != 4)
                    } else {
                        Text("STEP 2 OF 2 — CONFIRM PIN")
                            .font(.caption)
                            .foregroundColor(CzedrPalette.redPrimary)
                        CzedrPinEntryView(pin: $confirmPin, label: "CONFIRM NEW PIN", fieldId: 2)

                        Button(action: save) {
                            Text(session.isLoading ? "…" : "SAVE PIN")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(CzedrPalette.redPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .disabled(session.isLoading || confirmPin.count != 4)

                        Button(action: { step = 1; confirmPin = "" }) {
                            Text("Back to change PIN")
                                .font(.subheadline)
                                .foregroundColor(CzedrPalette.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                    }

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
                }
                .padding(16)
            }
        }
        .onAppear {
            step = 1
            pin = ""
            confirmPin = ""
            localMessage = ""
            session.clearError()
        }
    }

    private func goToConfirmStep() {
        session.clearError()
        localMessage = ""
        guard pin.count == 4 else {
            session.errorMessage = "PIN must be 4 digits"
            return
        }
        CzedrKeyboard.dismiss()
        confirmPin = ""
        step = 2
    }

    private func save() {
        session.clearError()
        localMessage = ""
        guard pin.count == 4, confirmPin.count == 4 else {
            session.errorMessage = "PIN must be 4 digits"
            return
        }
        guard pin == confirmPin else {
            session.errorMessage = "PINs do not match — tap Back and try again"
            return
        }
        CzedrKeyboard.dismiss()
        session.setAccountPin(pin) {
            localMessage = "PIN saved. You can send payments now."
            pin = ""
            confirmPin = ""
            step = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
