//
//  AppSession.swift
//

import Foundation
import Combine

struct ApiResolveError: Error {
    let message: String
}

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
    @Published var isMenuPresented = false
    @Published var hasPinSet = false
    @Published var paymentQrPayload = ""

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
        isMenuPresented = false
        hasPinSet = false
        paymentQrPayload = ""
    }

    /// QR string from API when available; otherwise built from Czedr ID.
    var effectivePaymentQrPayload: String {
        let trimmed = paymentQrPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let id = czedrId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return "" }
        return CzedrQrCode.paymentPayload(czedrId: id)
    }

    func presentMenu() {
        isMenuPresented = true
    }

    func dismissMenu() {
        isMenuPresented = false
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

    /// Scans Wi‑Fi for the PC running the Czedr API (same as legacy login).
    func discoverApiBase(completion: @escaping (Result<String, ApiResolveError>) -> Void) {
        CzedrLanAPIFinder.resolve { base, error in
            DispatchQueue.main.async {
                if let base, !base.isEmpty {
                    self.apiBase = base
                    KeychainStore.set(base, key: KeychainStore.Keys.apiBase)
                    completion(.success(base))
                } else {
                    let msg = error?.localizedDescription ?? "Could not find your Czedr server on Wi‑Fi."
                    completion(.failure(ApiResolveError(message: msg)))
                }
            }
        }
    }

    private func resolveApiBaseThen(
        override: String,
        completion: @escaping (Result<String, ApiResolveError>) -> Void
    ) {
        let trimmed = override.trimmingCharacters(in: .whitespacesAndNewlines)
        let attempt: (String) -> Void = { candidate in
            CzedrLanAPIFinder.testBaseURL(candidate) { reachable in
                DispatchQueue.main.async {
                    if reachable {
                        self.apiBase = candidate
                        KeychainStore.set(candidate, key: KeychainStore.Keys.apiBase)
                        completion(.success(candidate))
                    } else {
                        self.discoverApiBase(completion: completion)
                    }
                }
            }
        }
        if trimmed.isEmpty {
            discoverApiBase(completion: completion)
        } else {
            attempt(trimmed)
        }
    }

    func register(
        email: String,
        password: String,
        referrerCzedrId: String,
        apiBaseOverride: String
    ) {
        isLoading = true
        errorMessage = nil
        resolveApiBaseThen(override: apiBaseOverride) { [weak self] resolved in
            guard let self else { return }
            switch resolved {
            case .failure(let err):
                self.isLoading = false
                self.errorMessage = err.message
                return
            case .success(let base):
                self.performRegister(
                    email: email,
                    password: password,
                    referrerCzedrId: referrerCzedrId,
                    apiBase: base
                )
            }
        }
    }

    private func performRegister(
        email: String,
        password: String,
        referrerCzedrId: String,
        apiBase: String
    ) {
        api.register(
            email: email,
            password: password,
            referrerCzedrId: referrerCzedrId,
            apiBase: apiBase
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let payload):
                    self.persistSession(
                        token: payload.token,
                        email: payload.email,
                        czedrId: payload.czedrId,
                        apiBase: apiBase,
                        hasPinSet: payload.hasPinSet,
                        paymentQrPayload: payload.paymentQrPayload
                    )
                    self.refreshBalance()
                }
            }
        }
    }

    func login(email: String, password: String, apiBaseOverride: String) {
        isLoading = true
        errorMessage = nil
        resolveApiBaseThen(override: apiBaseOverride) { [weak self] resolved in
            guard let self else { return }
            switch resolved {
            case .failure(let err):
                self.isLoading = false
                self.errorMessage = err.message
                return
            case .success(let base):
                self.performLogin(email: email, password: password, apiBase: base)
            }
        }
    }

    private func performLogin(email: String, password: String, apiBase: String) {
        api.login(email: email, password: password, apiBase: apiBase) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let payload):
                    self.persistSession(
                        token: payload.token,
                        email: payload.email,
                        czedrId: payload.czedrId,
                        apiBase: apiBase,
                        hasPinSet: payload.hasPinSet,
                        paymentQrPayload: payload.paymentQrPayload
                    )
                    self.refreshBalance()
                }
            }
        }
    }

    func refreshProfile(completion: ((Bool) -> Void)? = nil) {
        guard isLoggedIn, !token.isEmpty else {
            completion?(false)
            return
        }
        api.fetchMe(apiBase: apiBase, token: token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                    completion?(false)
                case .ok(let profile):
                    if !profile.email.isEmpty { self.email = profile.email }
                    self.czedrId = profile.czedrId
                    self.hasPinSet = profile.hasPinSet
                    self.paymentQrPayload = profile.paymentQrPayload
                    KeychainStore.set(profile.email, key: KeychainStore.Keys.email)
                    KeychainStore.set(profile.czedrId, key: KeychainStore.Keys.czedrId)
                    completion?(true)
                }
            }
        }
    }

    func setAccountPin(_ pin: String, onSuccess: @escaping () -> Void) {
        if pin.count != 4 {
            errorMessage = "PIN must be 4 digits"
            return
        }
        isLoading = true
        api.setPin(apiBase: apiBase, token: token, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    if msg.localizedCaseInsensitiveContains("PIN already set") {
                        self.hasPinSet = true
                        self.errorMessage = nil
                        onSuccess()
                    } else {
                        self.errorMessage = msg
                    }
                case .ok:
                    self.hasPinSet = true
                    self.errorMessage = nil
                    onSuccess()
                }
            }
        }
    }

    func changeAccountPin(oldPin: String, newPin: String, onSuccess: @escaping () -> Void) {
        if oldPin.count != 4 || newPin.count != 4 {
            errorMessage = "PIN must be 4 digits"
            return
        }
        isLoading = true
        api.changePin(apiBase: apiBase, token: token, oldPin: oldPin, newPin: newPin) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok:
                    self.hasPinSet = true
                    self.errorMessage = nil
                    onSuccess()
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
        isMenuPresented = false
        hasPinSet = false
        paymentQrPayload = ""
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
                    self.errorMessage = nil
                    self.balanceCents = bal.balanceCents
                    self.balanceText = CzedrMoney.format(cents: bal.balanceCents, currency: bal.currency)
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

    func sendTransfer(
        to: String,
        amountDollars: String,
        memo: String,
        pin: String,
        recipientName: String = "",
        onSuccess: @escaping (PaymentSuccessDetails) -> Void
    ) {
        guard let cents = CzedrMoney.parseDollarsToCents(amountDollars) else {
            errorMessage = "Enter a valid amount"
            return
        }
        if pin.count != 4 {
            errorMessage = "PIN must be 4 digits"
            return
        }
        let recipientId = to.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if recipientId.isEmpty {
            errorMessage = "Enter recipient Czedr ID"
            return
        }
        isLoading = true
        api.transfer(apiBase: apiBase, token: token, toCzedrId: recipientId, amountCents: cents, memo: memo, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .err(let msg):
                    self.errorMessage = msg
                case .ok(let transfer):
                    self.refreshBalance()
                    onSuccess(
                        PaymentSuccessDetails(
                            transactionId: transfer.transactionId,
                            recipientCzedrId: recipientId,
                            recipientName: recipientName,
                            amountCents: cents,
                            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                }
            }
        }
    }

    func sendInvoice(
        to: String,
        amountDollars: String,
        description: String,
        pin: String,
        debtorName: String = "",
        onSuccess: @escaping (InvoiceSuccessDetails) -> Void
    ) {
        guard let cents = CzedrMoney.parseDollarsToCents(amountDollars) else {
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
        errorMessage = nil
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
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
                case .ok:
                    self.errorMessage = nil
                    onSuccess(
                        InvoiceSuccessDetails(
                            debtorCzedrId: toId,
                            debtorName: debtorName.trimmingCharacters(in: .whitespacesAndNewlines),
                            amountCents: cents,
                            description: desc
                        )
                    )
                }
            }
        }
    }

    func fetchFundingStatus(completion: @escaping (String, [BankLinkRow], String?) -> Void) {
        api.fetchFundingStatus(apiBase: apiBase, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .err(let msg):
                    completion("", [], msg)
                case .ok(let payload):
                    completion(payload.message, payload.banks, nil)
                }
            }
        }
    }

    func startBankLink(
        routing: String,
        account: String,
        holderName: String,
        accountType: String,
        completion: @escaping (APIResult<BankLinkStartResult>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        api.startBankLink(
            apiBase: apiBase,
            token: token,
            routing: routing,
            account: account,
            holderName: holderName,
            accountType: accountType
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .err(let msg):
                    completion(.err(msg))
                case .ok(let payload):
                    self?.actionMessage = payload.message
                    completion(.ok(payload))
                }
            }
        }
    }

    func confirmBankLink(
        bankLinkId: String,
        amount1Cents: Int,
        amount2Cents: Int,
        completion: @escaping (String?) -> Void
    ) {
        isLoading = true
        api.confirmBankLink(apiBase: apiBase, token: token, bankLinkId: bankLinkId, amount1Cents: amount1Cents, amount2Cents: amount2Cents) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .err(let msg):
                    completion(msg)
                case .ok:
                    self?.actionMessage = "Bank verified"
                    completion(nil)
                }
            }
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

    func fetchPendingInvoicesSent(completion: @escaping (Result<[InvoiceRow], String>) -> Void) {
        api.fetchInvoicesSent(apiBase: apiBase, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .err(let msg): completion(.failure(msg))
                case .ok(let rows): completion(.success(rows))
                }
            }
        }
    }

    func fetchReferralEarnings(completion: @escaping (Result<ReferralEarnings, String>) -> Void) {
        api.fetchReferralEarnings(apiBase: apiBase, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .err(let msg): completion(.failure(msg))
                case .ok(let data): completion(.success(data))
                }
            }
        }
    }

    func fetchPendingInvoicesReceived(completion: @escaping (Result<[InvoiceRow], String>) -> Void) {
        api.fetchInvoicesReceived(apiBase: apiBase, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .err(let msg): completion(.failure(msg))
                case .ok(let rows): completion(.success(rows))
                }
            }
        }
    }

    private func persistSession(
        token: String,
        email: String,
        czedrId: String,
        apiBase: String,
        hasPinSet: Bool,
        paymentQrPayload: String = ""
    ) {
        self.token = token
        self.email = email
        self.czedrId = czedrId
        self.apiBase = apiBase
        self.hasPinSet = hasPinSet
        self.paymentQrPayload = paymentQrPayload
        KeychainStore.set(token, key: KeychainStore.Keys.token)
        KeychainStore.set(email, key: KeychainStore.Keys.email)
        KeychainStore.set(czedrId, key: KeychainStore.Keys.czedrId)
        KeychainStore.set(apiBase, key: KeychainStore.Keys.apiBase)
        isLoggedIn = true
    }

    static func formatMoney(cents: Int64, currency: String) -> String {
        CzedrMoney.format(cents: cents, currency: currency)
    }
}
