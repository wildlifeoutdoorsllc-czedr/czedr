//
//  AppSession.swift
//

import Foundation
import Combine

final class AppSession: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published var email = ""
    @Published var czedrId = ""
    @Published var apiBase = ""
    @Published var balanceText = "—"
    @Published var balanceCents: Int64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionMessage: String?

    private var token = ""
    private let api = CzedrAPIClient()

    init() {
        resetToLoggedOut()
    }

    /// Clears in-memory session (Keychain cleared separately on cold launch).
    func resetToLoggedOut() {
        token = ""
        email = ""
        czedrId = ""
        apiBase = defaultApiBase()
        balanceText = "—"
        balanceCents = 0
        isLoggedIn = false
        isLoading = false
        errorMessage = nil
        actionMessage = nil
    }

    var buildLabel: String {
        let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "SwiftUI · Build \(v)"
    }

    func defaultApiBase() -> String {
        let stored = KeychainStore.get(KeychainStore.Keys.apiBase)
        if let stored, !stored.isEmpty { return stored }
        return CzedrEffectiveAPIBase()
    }

    func clearError() { errorMessage = nil }

    func register(
        email: String,
        password: String,
        referrerCzedrId: String,
        apiBaseOverride: String
    ) {
        let base = apiBaseOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultApiBase()
            : apiBaseOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        errorMessage = nil
        api.register(
            email: email,
            password: password,
            referrerCzedrId: referrerCzedrId,
            apiBase: base
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let payload):
                    self.persistSession(token: payload.token, email: payload.email, czedrId: payload.czedrId, apiBase: base)
                    self.refreshBalance()
                }
            }
        }
    }

    func login(email: String, password: String, apiBaseOverride: String) {
        let base = apiBaseOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultApiBase()
            : apiBaseOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        errorMessage = nil
        api.login(email: email, password: password, apiBase: base) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let payload):
                    self.persistSession(token: payload.token, email: payload.email, czedrId: payload.czedrId, apiBase: base)
                    self.refreshBalance()
                }
            }
        }
    }

    func logout() {
        let base = apiBase
        let tok = token
        api.logout(apiBase: base, token: tok)
        KeychainStore.clearSession()
        token = ""
        email = ""
        czedrId = ""
        balanceText = "—"
        balanceCents = 0
        isLoggedIn = false
        errorMessage = nil
        actionMessage = nil
    }

    func refreshBalance() {
        guard isLoggedIn else { return }
        isLoading = true
        api.fetchBalance(apiBase: apiBase, token: token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let bal):
                    self.balanceCents = bal.balanceCents
                    self.balanceText = Self.formatMoney(cents: bal.balanceCents, currency: bal.currency)
                }
            }
        }
    }

    func validateRecipient(_ id: String, completion: @escaping (String?) -> Void) {
        api.validateRecipient(apiBase: apiBase, token: token, czedrId: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                    completion(nil)
                case .ok(let name):
                    completion(name)
                }
            }
        }
    }

    func sendTransfer(to: String, amountDollars: String, memo: String, pin: String) {
        guard let cents = Self.parseCents(fromDollars: amountDollars) else {
            errorMessage = "Enter a valid amount"
            return
        }
        if pin.count != 4 {
            errorMessage = "PIN must be 4 digits"
            return
        }
        isLoading = true
        api.transfer(apiBase: apiBase, token: token, toCzedrId: to, amountCents: cents, memo: memo, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok:
                    self.actionMessage = "Payment sent"
                    self.refreshBalance()
                }
            }
        }
    }

    func sendInvoice(to: String, amountDollars: String, description: String, pin: String) {
        guard Self.parseCents(fromDollars: amountDollars) != nil else {
            errorMessage = "Enter a valid amount"
            return
        }
        if pin.count != 4 {
            errorMessage = "PIN must be 4 digits"
            return
        }
        let toId = to.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if toId.isEmpty {
            errorMessage = "Enter debtor Czedr ID"
            return
        }
        isLoading = true
        api.createInvoice(
            apiBase: apiBase,
            token: token,
            toCzedrId: toId,
            amountDollars: amountDollars,
            description: description,
            pin: pin
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let msg):
                    self.actionMessage = msg
                }
            }
        }
    }

    func fetchPendingInvoices(completion: @escaping ([InvoiceRow], [InvoiceRow]) -> Void) {
        isLoading = true
        let group = DispatchGroup()
        var received: [InvoiceRow] = []
        var sent: [InvoiceRow] = []
        var hadError = false

        group.enter()
        api.fetchReceivedInvoices(apiBase: apiBase, token: token) { result in
            if case .ok(let rows) = result { received = rows }
            if case .err = result { hadError = true }
            group.leave()
        }

        group.enter()
        api.fetchSentInvoices(apiBase: apiBase, token: token) { result in
            if case .ok(let rows) = result { sent = rows }
            if case .err = result { hadError = true }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            if hadError, received.isEmpty, sent.isEmpty {
                self?.errorMessage = self?.errorMessage ?? "Could not load invoices"
            }
            completion(received, sent)
        }
    }

    func fetchHistory(completion: @escaping ([TransferRow]) -> Void) {
        isLoading = true
        api.fetchHistory(apiBase: apiBase, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .err(let msg):
                    self?.errorMessage = msg
                    completion([])
                case .ok(let rows):
                    completion(rows)
                }
            }
        }
    }

    private func persistSession(token: String, email: String, czedrId: String, apiBase: String) {
        self.token = token
        self.email = email
        self.czedrId = czedrId
        self.apiBase = apiBase
        KeychainStore.set(token, key: KeychainStore.Keys.token)
        KeychainStore.set(email, key: KeychainStore.Keys.email)
        KeychainStore.set(czedrId, key: KeychainStore.Keys.czedrId)
        KeychainStore.set(apiBase, key: KeychainStore.Keys.apiBase)
        isLoggedIn = true
    }

    static func formatMoney(cents: Int64, currency: String) -> String {
        let amount = Double(cents) / 100.0
        return String(format: "$%.2f %@", amount, currency)
    }

    static func parseCents(fromDollars s: String) -> Int64? {
        let cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return Int64((value * 100.0).rounded())
    }
}
