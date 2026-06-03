//
//  CzedrInvoiceScreens.swift
//  Send Invoice — request payment from someone who owes you.
//

import SwiftUI
import UIKit

// MARK: - Send Invoice

struct SendInvoiceScreen: View {
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @State private var debtorId = ""
    @State private var validatedName = ""
    @State private var amount = ""
    @State private var description = ""
    @State private var pin = ""
    @State private var showQrScanner = false

    var body: some View {
        LoggedInPageLayout(title: "Send Invoice", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Request payment from someone who owes you.")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        CzedrPlaceholderTextField(
                            placeholder: "Debtor Czedr ID",
                            text: $debtorId,
                            autocapitalization: .allCharacters
                        )
                        Button(action: { showQrScanner = true }) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(CzedrPalette.orangeField)
                                .foregroundColor(CzedrPalette.fieldText)
                                .cornerRadius(4)
                        }
                        .accessibilityLabel("Scan Czedr QR code")

                        Button("VALIDATE") { validate() }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .background(CzedrPalette.redPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    Text("Scan, type, or paste a Czedr ID (e.g. from a text message).")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: pasteDebtorFromClipboard) {
                        Text("Paste ID from clipboard")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(CzedrPalette.cheddarGold)
                    }

                    if !validatedName.isEmpty {
                        Text(validatedName).font(.footnote).foregroundColor(CzedrPalette.balanceGreen)
                    }

                    CzedrPlaceholderTextField(
                        placeholder: "Amount they owe ($)",
                        text: $amount,
                        keyboard: .decimalPad
                    )
                    .frame(minHeight: 56)

                    CzedrPlaceholderTextField(placeholder: "Description", text: $description)

                    CzedrPinEntryView(pin: $pin)
                        .padding(.top, 12)

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

                    if let err = session.errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(CzedrPalette.redPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .sheet(isPresented: $showQrScanner) {
                CzedrQrScannerSheet(
                    onScan: handleScannedPayload,
                    onCancel: { showQrScanner = false }
                )
            }
        }
    }

    private func handleScannedPayload(_ raw: String) {
        showQrScanner = false
        guard let id = CzedrQrCode.parseCzedrId(from: raw) else {
            session.errorMessage = "Could not read a Czedr ID from that QR code."
            return
        }
        debtorId = id
        validatedName = ""
        validate()
    }

    private func pasteDebtorFromClipboard() {
        session.clearError()
        guard let raw = UIPasteboard.general.string, !raw.isEmpty else {
            session.errorMessage = "Nothing to paste from the clipboard."
            return
        }
        guard let id = CzedrQrCode.parseCzedrId(from: raw) else {
            session.errorMessage = "Clipboard does not contain a valid Czedr ID."
            return
        }
        debtorId = id
        validatedName = ""
        validate()
    }

    private func validate() {
        session.clearError()
        session.validateRecipient(debtorId) { name in
            validatedName = name ?? ""
        }
    }

    private func sendInvoice() {
        session.clearError()
        CzedrKeyboard.dismiss()
        session.sendInvoice(
            to: debtorId,
            amountDollars: amount,
            description: description,
            pin: pin
        )
    }
}
