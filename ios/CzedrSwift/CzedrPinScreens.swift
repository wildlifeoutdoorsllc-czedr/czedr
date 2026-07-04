//
//  CzedrPinScreens.swift
//  Set / change account PIN (required before payments).
//

import SwiftUI

struct SetPinScreen: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.presentationMode) private var presentationMode
    @State private var step = 1
    @State private var oldPin = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var localMessage = ""

    private var isChangeFlow: Bool { session.hasPinSet }

    var body: some View {
        LoggedInPageLayout(title: isChangeFlow ? "Change PIN" : "Set PIN", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(isChangeFlow
                         ? "Enter your current PIN, then choose a new 4-digit PIN."
                         : "Create a 4-digit PIN. You will enter this when sending money or invoices.")
                        .font(.footnote)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    stepContent()

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
        .onAppear(perform: resetForm)
    }

    @ViewBuilder
    private func stepContent() -> some View {
        if isChangeFlow && step == 0 {
            Text("STEP 1 — CURRENT PIN")
                .font(.caption)
                .foregroundColor(CzedrPalette.redPrimary)
            CzedrPinEntryView(pin: $oldPin, label: "CURRENT PIN", fieldId: 0)
            primaryButton("NEXT", enabled: oldPin.count == 4, action: {
                guard oldPin.count == 4 else {
                    session.errorMessage = "PIN must be 4 digits"
                    return
                }
                session.clearError()
                CzedrKeyboard.dismiss()
                pin = ""
                confirmPin = ""
                step = 1
            })
        } else if step == 1 {
            Text(isChangeFlow ? "STEP 2 OF 3 — NEW PIN" : "STEP 1 OF 2 — NEW PIN")
                .font(.caption)
                .foregroundColor(CzedrPalette.redPrimary)
            CzedrPinEntryView(pin: $pin, label: "ENTER NEW PIN", fieldId: 1)
            primaryButton("NEXT", enabled: pin.count == 4, action: goToConfirmStep)
            if isChangeFlow {
                secondaryButton("Back to current PIN") { step = 0; pin = "" }
            }
        } else {
            Text(isChangeFlow ? "STEP 3 OF 3 — CONFIRM NEW PIN" : "STEP 2 OF 2 — CONFIRM PIN")
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
            secondaryButton("Back to change PIN") { step = 1; confirmPin = "" }
        }
    }

    private func primaryButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(CzedrPalette.charcoalButton)
                .foregroundColor(CzedrPalette.lightText)
                .cornerRadius(6)
        }
        .disabled(!enabled)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(CzedrPalette.caption)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private func resetForm() {
        step = session.hasPinSet ? 0 : 1
        oldPin = ""
        pin = ""
        confirmPin = ""
        localMessage = ""
        session.clearError()
    }

    private func goToConfirmStep() {
        session.clearError()
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
        guard pin.count == 4, confirmPin.count == 4 else {
            session.errorMessage = "PIN must be 4 digits"
            return
        }
        guard pin == confirmPin else {
            session.errorMessage = "PINs do not match — tap Back and try again"
            return
        }
        CzedrKeyboard.dismiss()

        if isChangeFlow {
            session.changeAccountPin(oldPin: oldPin, newPin: pin) {
                finishSuccess()
            }
        } else {
            session.setAccountPin(pin) {
                finishSuccess()
            }
        }
    }

    private func finishSuccess() {
        localMessage = "PIN saved. You can send payments now."
        oldPin = ""
        pin = ""
        confirmPin = ""
        step = session.hasPinSet ? 0 : 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Forgot PIN

struct ForgotPinScreen: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.presentationMode) private var presentationMode
    @State private var step = 1
    @State private var password = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var localMessage = ""
    @State private var isPasswordVisible = false

    var body: some View {
        LoggedInPageLayout(title: "Forgot PIN", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Verify your account password to set a new PIN.")
                        .font(.footnote)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    stepContent()

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
            password = ""
            newPin = ""
            confirmPin = ""
            localMessage = ""
            step = 1
            session.clearError()
        }
    }

    @ViewBuilder
    private func stepContent() -> some View {
        if step == 1 {
            Text("STEP 1 OF 3 -- ACCOUNT PASSWORD")
                .font(.caption)
                .foregroundColor(CzedrPalette.redPrimary)

            HStack {
                if isPasswordVisible {
                    CzedrPlaceholderTextField(placeholder: "Enter your password", text: $password)
                } else {
                    SecureField("Enter your password", text: $password)
                        .padding(14)
                        .background(CzedrPalette.orangeField)
                        .foregroundColor(CzedrPalette.fieldText)
                        .cornerRadius(4)
                }
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(CzedrPalette.caption)
                }
            }

            actionButton("NEXT", enabled: !password.isEmpty) {
                session.clearError()
                CzedrKeyboard.dismiss()
                newPin = ""
                confirmPin = ""
                step = 2
            }
        } else if step == 2 {
            Text("STEP 2 OF 3 -- NEW PIN")
                .font(.caption)
                .foregroundColor(CzedrPalette.redPrimary)
            CzedrPinEntryView(pin: $newPin, label: "ENTER NEW PIN", fieldId: 10)
            actionButton("NEXT", enabled: newPin.count == 4) {
                session.clearError()
                guard newPin.count == 4 else {
                    session.errorMessage = "PIN must be 4 digits"
                    return
                }
                CzedrKeyboard.dismiss()
                confirmPin = ""
                step = 3
            }
            backButton("Back to password") { step = 1; newPin = "" }
        } else {
            Text("STEP 3 OF 3 -- CONFIRM NEW PIN")
                .font(.caption)
                .foregroundColor(CzedrPalette.redPrimary)
            CzedrPinEntryView(pin: $confirmPin, label: "CONFIRM NEW PIN", fieldId: 11)
            Button(action: save) {
                Text(session.isLoading ? "..." : "RESET PIN")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CzedrPalette.redPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .disabled(session.isLoading || confirmPin.count != 4)
            backButton("Back to new PIN") { step = 2; confirmPin = "" }
        }
    }

    private func actionButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(CzedrPalette.charcoalButton)
                .foregroundColor(CzedrPalette.lightText)
                .cornerRadius(6)
        }
        .disabled(!enabled)
    }

    private func backButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(CzedrPalette.caption)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private func save() {
        session.clearError()
        guard newPin.count == 4, confirmPin.count == 4 else {
            session.errorMessage = "PIN must be 4 digits"
            return
        }
        guard newPin == confirmPin else {
            session.errorMessage = "PINs do not match -- tap Back and try again"
            return
        }
        CzedrKeyboard.dismiss()
        session.resetAccountPin(password: password, newPin: newPin) {
            localMessage = "PIN has been reset. You can send payments now."
            password = ""
            newPin = ""
            confirmPin = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
