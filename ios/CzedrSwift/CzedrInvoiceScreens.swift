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

// MARK: - Pending Invoices

private enum PendingInvoiceTab: String, CaseIterable, Identifiable {
    case waitingOnThem = "Waiting on them"
    case youOwe = "You owe"

    var id: String { rawValue }
}

struct PendingInvoicesScreen: View {
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @State private var tab: PendingInvoiceTab = .waitingOnThem
    @State private var sentRows: [InvoiceRow] = []
    @State private var receivedRows: [InvoiceRow] = []
    @State private var screenError: String?
    @State private var isLoading = false

    private var activeRows: [InvoiceRow] {
        tab == .waitingOnThem ? sentRows : receivedRows
    }

    var body: some View {
        LoggedInPageLayout(title: "Pending Invoices", showBack: true, onMenu: { session.presentMenu() }) {
            VStack(spacing: 0) {
                Picker("Invoice type", selection: $tab) {
                    ForEach(PendingInvoiceTab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if isLoading && activeRows.isEmpty {
                    Spacer()
                    Text("Loading…")
                        .foregroundColor(CzedrPalette.caption)
                    Spacer()
                } else if let err = screenError, activeRows.isEmpty {
                    Spacer()
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(CzedrPalette.redPrimary)
                        .multilineTextAlignment(.center)
                        .padding(16)
                    Spacer()
                } else if activeRows.isEmpty {
                    Spacer()
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(CzedrPalette.caption)
                        .multilineTextAlignment(.center)
                        .padding(16)
                    Spacer()
                } else {
                    List(activeRows) { row in
                        invoiceRow(row)
                            .listRowBackground(CzedrPalette.surface)
                    }
                }
            }
        }
        .onAppear(perform: loadAll)
        .onChange(of: tab) { _ in screenError = nil }
    }

    private var emptyMessage: String {
        switch tab {
        case .waitingOnThem:
            return "No invoices waiting on payment.\nUse Send Invoice to request money from someone."
        case .youOwe:
            return "No invoices to pay right now."
        }
    }

    private func invoiceRow(_ row: InvoiceRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(CzedrMoney.format(cents: row.amountCents))
                .font(.headline)
                .foregroundColor(CzedrPalette.balanceGreen)
            Text(row.description.isEmpty ? "Invoice" : row.description)
                .foregroundColor(CzedrPalette.lightText)
            Text(counterpartyLine(row))
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
            if !row.createdAt.isEmpty {
                Text(row.createdAt)
                    .font(.caption2)
                    .foregroundColor(CzedrPalette.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private func counterpartyLine(_ row: InvoiceRow) -> String {
        let id = row.counterpartyCzedrId.uppercased()
        let label = row.counterpartyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if label.isEmpty || label.uppercased() == id || label.contains("@") {
            return tab == .waitingOnThem ? "To \(id)" : "From \(id)"
        }
        return tab == .waitingOnThem ? "To \(label) (\(id))" : "From \(label) (\(id))"
    }

    private func loadAll() {
        screenError = nil
        isLoading = true
        sentRows = []
        receivedRows = []
        let group = DispatchGroup()
        var loadError: String?

        group.enter()
        session.fetchPendingInvoicesSent { result in
            switch result {
            case .success(let rows): sentRows = rows
            case .failure(let msg): loadError = msg
            }
            group.leave()
        }

        group.enter()
        session.fetchPendingInvoicesReceived { result in
            switch result {
            case .success(let rows): receivedRows = rows
            case .failure(let msg): loadError = loadError ?? msg
            }
            group.leave()
        }

        group.notify(queue: .main) {
            isLoading = false
            screenError = loadError
        }
    }
}
