//
//  CzedrFundingScreens.swift
//  + My Bank — micro-deposit only; ledger-first (no bank password).
//

import SwiftUI

// MARK: - + My Bank

struct MyBankScreen: View {
    @EnvironmentObject var session: AppSession
    @State private var statusMessage = ""
    @State private var banks: [BankLinkRow] = []
    @State private var showLinkForm = false
    @State private var routing = ""
    @State private var account = ""
    @State private var holderName = ""
    @State private var accountType = "checking"
    @State private var confirmLinkId = ""
    @State private var amount1 = ""
    @State private var amount2 = ""
    @State private var devHintA = ""
    @State private var devHintB = ""
    @State private var screenError: String?

    var body: some View {
        LoggedInPageLayout(title: "+ My Bank", showBack: true, onMenu: { session.presentMenu() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Pay and receive on Czedr using your balance—no bank required. Link a bank only for cash in or out later. We never ask for your online banking password.")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    if !banks.isEmpty {
                        Text("Linked accounts")
                            .font(.caption.bold())
                            .foregroundColor(CzedrPalette.lightText)
                        ForEach(banks) { bank in
                            bankRow(bank)
                        }
                    }

                    Button(action: { showLinkForm.toggle() }) {
                        Text(showLinkForm ? "Hide form" : "+ Link my bank")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CzedrPalette.orangeField)
                            .foregroundColor(CzedrPalette.fieldText)
                            .cornerRadius(6)
                    }

                    if showLinkForm {
                        linkForm
                    }

                    if !confirmLinkId.isEmpty {
                        confirmSection
                    }

                    if let err = screenError {
                        Text(err).font(.footnote).foregroundColor(CzedrPalette.redPrimary)
                    }
                    if let ok = session.actionMessage {
                        Text(ok).font(.footnote).foregroundColor(CzedrPalette.balanceGreen)
                    }
                }
                .padding(16)
            }
        }
        .onAppear(perform: reload)
    }

    private func bankRow(_ bank: BankLinkRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(bank.accountType.capitalized) •••• \(bank.last4)")
                    .foregroundColor(CzedrPalette.lightText)
                Text(bank.statusLabel)
                    .font(.caption)
                    .foregroundColor(bank.status == "verified" ? CzedrPalette.balanceGreen : CzedrPalette.caption)
            }
            Spacer()
            if bank.status == "awaiting_confirm" {
                Button("Confirm") {
                    confirmLinkId = bank.id
                    amount1 = ""
                    amount2 = ""
                }
                .font(.caption.bold())
                .foregroundColor(CzedrPalette.redPrimary)
            }
        }
        .padding(12)
        .background(CzedrPalette.surface)
        .cornerRadius(6)
    }

    private var linkForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Routing & account (micro-deposit verification)")
                .font(.caption.bold())
                .foregroundColor(CzedrPalette.lightText)
            CzedrPlaceholderTextField(placeholder: "Routing number (9 digits)", text: $routing, keyboard: .numberPad)
            CzedrPlaceholderTextField(placeholder: "Account number", text: $account, keyboard: .numberPad)
            CzedrPlaceholderTextField(placeholder: "Name on account", text: $holderName)
            Picker("Account type", selection: $accountType) {
                Text("Checking").tag("checking")
                Text("Savings").tag("savings")
            }
            .pickerStyle(SegmentedPickerStyle())
            Button(action: startLink) {
                Text(session.isLoading ? "…" : "Start verification")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CzedrPalette.redPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .disabled(session.isLoading)
        }
    }

    private var confirmSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Confirm micro-deposits")
                .font(.caption.bold())
                .foregroundColor(CzedrPalette.redPrimary)
            if !devHintA.isEmpty {
                Text("Enter amounts in cents (e.g. \(devHintA) and \(devHintB))")
                    .font(.caption2)
                    .foregroundColor(CzedrPalette.caption)
            }
            CzedrPlaceholderTextField(placeholder: "First amount (cents)", text: $amount1, keyboard: .numberPad)
            CzedrPlaceholderTextField(placeholder: "Second amount (cents)", text: $amount2, keyboard: .numberPad)
            Button(action: confirmLink) {
                Text(session.isLoading ? "…" : "Verify amounts")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CzedrPalette.charcoalButton)
                    .foregroundColor(CzedrPalette.lightText)
                    .cornerRadius(6)
            }
            .disabled(session.isLoading)
        }
        .padding(.top, 8)
    }

    private func reload() {
        screenError = nil
        session.fetchFundingStatus { msg, list, err in
            statusMessage = msg
            banks = list
            screenError = err
            if let pending = list.first(where: { $0.status == "awaiting_confirm" }) {
                confirmLinkId = pending.id
            }
        }
    }

    private func startLink() {
        screenError = nil
        session.startBankLink(
            routing: routing,
            account: account,
            holderName: holderName,
            accountType: accountType
        ) { result in
            switch result {
            case .err(let msg):
                screenError = msg
            case .ok(let payload):
                session.actionMessage = payload.message
                if let a = payload.microCentsA, let b = payload.microCentsB {
                    devHintA = "\(a)"
                    devHintB = "\(b)"
                    confirmLinkId = payload.bankLinkId
                }
                routing = ""
                account = ""
                showLinkForm = false
                reload()
            }
        }
    }

    private func confirmLink() {
        guard let c1 = Int(amount1.trimmingCharacters(in: .whitespaces)), let c2 = Int(amount2.trimmingCharacters(in: .whitespaces)) else {
            screenError = "Enter both amounts in cents"
            return
        }
        screenError = nil
        session.confirmBankLink(bankLinkId: confirmLinkId, amount1Cents: c1, amount2Cents: c2) { err in
            if let err {
                screenError = err
                return
            }
            confirmLinkId = ""
            amount1 = ""
            amount2 = ""
            devHintA = ""
            devHintB = ""
            reload()
        }
    }
}

struct BankLinkRow: Identifiable {
    let id: String
    let last4: String
    let accountType: String
    let status: String

    var statusLabel: String {
        switch status {
        case "verified", "active": return "Verified"
        case "awaiting_confirm": return "Confirm two deposits"
        case "pending_micro_send": return "Deposits sending…"
        case "failed": return "Failed — link again"
        default: return status
        }
    }
}

struct BankLinkStartResult {
    let bankLinkId: String
    let message: String
    let microCentsA: Int?
    let microCentsB: Int?
}
