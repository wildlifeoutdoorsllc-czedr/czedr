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
    @State private var showSuccess = false
    @State private var successDetails: InvoiceSuccessDetails?

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
                        placeholder: "Enter amount",
                        text: $amount,
                        keyboard: .decimalPad
                    )
                    .frame(minHeight: 56)

                    CzedrPlaceholderTextField(placeholder: "Description", text: $description)

                    if !session.hasPinSet {
                        Text("Set a 4-digit PIN in Profile before you can send invoices.")
                            .font(.footnote)
                            .foregroundColor(CzedrPalette.redPrimary)
                        NavigationLink(destination: SetPinScreen()) {
                            Text("SET PIN NOW")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(CzedrPalette.redPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    } else {
                        CzedrPinEntryView(pin: $pin)
                            .padding(.top, 12)
                    }

                    Button(action: sendInvoice) {
                        Text(session.isLoading ? "…" : "SEND INVOICE")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                    .disabled(session.isLoading || !session.hasPinSet)
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
            .background(
                NavigationLink(
                    destination: successDestination,
                    isActive: $showSuccess
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .sheet(isPresented: $showQrScanner) {
                CzedrQrScannerSheet(
                    onScan: handleScannedPayload,
                    onCancel: { showQrScanner = false }
                )
            }
        }
    }

    @ViewBuilder
    private var successDestination: some View {
        if let details = successDetails {
            InvoiceSuccessScreen(
                details: details,
                isPresented: $showSuccess,
                onDone: resetForm
            )
        } else {
            EmptyView()
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
            pin: pin,
            debtorName: validatedName
        ) { details in
            successDetails = details
            showSuccess = true
        }
    }

    private func resetForm() {
        debtorId = ""
        validatedName = ""
        amount = ""
        description = ""
        pin = ""
        successDetails = nil
        session.clearError()
    }
}
