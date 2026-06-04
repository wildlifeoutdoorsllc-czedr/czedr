//
//  CzedrAPIClient.swift
//  v1 JSON API — same envelope as Android CzedrApi.kt
//

import Foundation

enum APIResult<T> {
    case ok(T)
    case err(String)
}

struct BalanceInfo {
    let balanceCents: Int64
    let currency: String
    let transferFeeCents: Int64
}

struct TransferRow: Identifiable {
    let id: String
    let amountCents: Int64
    let currency: String
    let memo: String
    let createdAt: String
    let fromCzedrId: String
    let toCzedrId: String
    let status: String
}

struct ReferralCredit: Identifiable {
    let id: String
    let amountCents: Int64
    let createdAt: String
    let memo: String
}

struct ReferralEarnings {
    let totalCents: Int64
    let paymentCount: Int
    let currency: String
    let recent: [ReferralCredit]
}

struct InvoiceRow: Identifiable {
    let id: String
    let counterpartyCzedrId: String
    let counterpartyLabel: String
    let amountCents: Int64
    let description: String
    let createdAt: String
    let direction: String
}

struct PaymentTransferResult {
    let transactionId: String?
}

struct MeProfile {
    let email: String
    let czedrId: String
    let hasPinSet: Bool
    let paymentQrPayload: String
}

struct AuthPayload {
    let token: String
    let email: String
    let czedrId: String
    let hasPinSet: Bool
    let paymentQrPayload: String
}

final class CzedrAPIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(
        email: String,
        password: String,
        apiBase: String,
        completion: @escaping (APIResult<AuthPayload>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let body: [String: Any] = [
            "user_email": email,
            "email": email,
            "user_pwd": password,
            "password": password,
        ]
        postJSON(base: base, path: "/v1/auth/login", body: body, token: nil) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                completion(Self.parseAuthPayload(data, fallbackEmail: email))
            }
        }
    }

    func forgotPassword(
        email: String,
        apiBase: String,
        completion: @escaping (APIResult<String>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: [String: Any] = [
            "user_email": trimmed,
            "email": trimmed,
        ]
        postJSON(base: base, path: "/v1/auth/forgot-password", body: body, token: nil) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                let message = (data["message"] as? String) ?? "If an account exists for this email, password reset instructions have been sent."
                completion(.ok(message))
            }
        }
    }

    func resetPassword(
        resetToken: String,
        newPassword: String,
        apiBase: String,
        completion: @escaping (APIResult<Void>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let token = Self.normalizeResetToken(resetToken)
        if token.isEmpty {
            completion(.err("Reset code is required"))
            return
        }
        let body: [String: Any] = [
            "reset_token": token,
            "password": newPassword,
        ]
        postJSON(base: base, path: "/v1/auth/reset-password", body: body, token: nil) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok:
                completion(.ok(()))
            }
        }
    }

    /// Accepts a raw token or a full reset URL from email (`#reset=…`).
    static func normalizeResetToken(_ raw: String) -> String {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let hash = t.range(of: "#reset=") {
            t = String(t[hash.upperBound...])
        } else if let hash = t.range(of: "reset=") {
            t = String(t[hash.upperBound...])
        }
        if let q = t.firstIndex(of: "?") {
            t = String(t[..<q])
        }
        if let amp = t.firstIndex(of: "&") {
            t = String(t[..<amp])
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func register(
        email: String,
        password: String,
        referrerCzedrId: String?,
        apiBase: String,
        completion: @escaping (APIResult<AuthPayload>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        var body: [String: Any] = [
            "email": email,
            "password": password,
        ]
        let ref = referrerCzedrId?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        if !ref.isEmpty {
            body["referrer_czedr_id"] = ref
        }
        postJSON(base: base, path: "/v1/auth/register", body: body, token: nil) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                completion(Self.parseAuthPayload(data, fallbackEmail: email))
            }
        }
    }

    func fetchMe(
        apiBase: String,
        token: String,
        completion: @escaping (APIResult<MeProfile>) -> Void
    ) {
        authedGetObject(
            base: apiBase,
            path: "/v1/me",
            token: token,
            map: { data in
                let cid = (data["czedr_id"] as? String) ?? ""
                if cid.isEmpty {
                    return .err("No Czedr ID in profile")
                }
                let qr = Self.paymentQrPayload(from: data, czedrId: cid)
                let pinFlag = (data["user_pin"] as? String) ?? "0"
                return .ok(MeProfile(
                    email: (data["email"] as? String) ?? "",
                    czedrId: cid,
                    hasPinSet: pinFlag == "1",
                    paymentQrPayload: qr
                ))
            },
            completion: completion
        )
    }

    func changePin(
        apiBase: String,
        token: String,
        oldPin: String,
        newPin: String,
        completion: @escaping (APIResult<Void>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let body: [String: Any] = [
            "old_pin": oldPin,
            "new_pin": newPin,
            "user_pin_old": oldPin,
            "user_pin": newPin,
        ]
        postJSON(base: base, path: "/v1/auth/pin/update", body: body, token: token) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok:
                completion(.ok(()))
            }
        }
    }

    private static func parseAuthPayload(
        _ data: [String: Any],
        fallbackEmail: String
    ) -> APIResult<AuthPayload> {
        let auth = (data["auth_code"] as? String) ?? (data["auth_token"] as? String) ?? ""
        if auth.isEmpty {
            return .err("No auth token in response")
        }
        let user = data["user"] as? [String: Any]
        let em = (user?["email"] as? String) ?? (data["email"] as? String) ?? fallbackEmail
        let cid = (user?["czedr_id"] as? String) ?? (data["czedr_id"] as? String) ?? (data["id"] as? String) ?? ""
        if cid.isEmpty {
            return .err("No Czedr ID in response")
        }
        let pinFlag = (data["user_pin"] as? String) ?? (user?["user_pin"] as? String) ?? "0"
        let qr = paymentQrPayload(from: data, czedrId: cid)
        return .ok(AuthPayload(token: auth, email: em, czedrId: cid, hasPinSet: pinFlag == "1", paymentQrPayload: qr))
    }

    private static func paymentQrPayload(from data: [String: Any], czedrId: String) -> String {
        let user = data["user"] as? [String: Any]
        let fromApi = (data["payment_qr_payload"] as? String) ?? (user?["payment_qr_payload"] as? String) ?? ""
        if !fromApi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromApi.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return CzedrQrCode.paymentPayload(czedrId: czedrId)
    }

    func setPin(
        apiBase: String,
        token: String,
        pin: String,
        completion: @escaping (APIResult<Void>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let body: [String: Any] = ["user_pin": pin]
        postJSON(base: base, path: "/v1/auth/pin/set", body: body, token: token) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok:
                completion(.ok(()))
            }
        }
    }

    func logout(apiBase: String, token: String) {
        guard let base = Self.normalizeBase(apiBase), !token.isEmpty else { return }
        var req = URLRequest(url: URL(string: "\(base)/v1/auth/logout")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        session.dataTask(with: req).resume()
    }

    func fetchBalance(apiBase: String, token: String, completion: @escaping (APIResult<BalanceInfo>) -> Void) {
        authedGetObject(
            base: apiBase,
            path: "/v1/ledger/balance",
            token: token,
            map: { data in
                .ok(BalanceInfo(
                    balanceCents: Self.int64(data["balance_cents"]),
                    currency: data["currency"] as? String ?? "USD",
                    transferFeeCents: Self.int64(data["transfer_fee_cents"])
                ))
            },
            completion: completion
        )
    }

    func validateRecipient(apiBase: String, token: String, czedrId: String, completion: @escaping (APIResult<String>) -> Void) {
        let q = czedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        authedGetObject(
            base: apiBase,
            path: "/v1/users/validate?czedr_id=\(encoded)",
            token: token,
            map: { data in
                let name = (data["display_name"] as? String) ?? (data["result"] as? String) ?? q
                return .ok(name.isEmpty ? q : name)
            },
            completion: completion
        )
    }

    func transfer(
        apiBase: String,
        token: String,
        toCzedrId: String,
        amountCents: Int64,
        memo: String,
        pin: String,
        completion: @escaping (APIResult<PaymentTransferResult>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        let body: [String: Any] = [
            "to_czedr_id": toCzedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            "amount_cents": amountCents,
            "idempotency_key": "ios-\(UUID().uuidString)",
            "memo": memo.isEmpty ? "Description" : memo,
            "user_pin": pin,
        ]
        postJSON(base: base, path: "/v1/transfers", body: body, token: token) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                let txnId = data["id"] as? String
                completion(.ok(PaymentTransferResult(transactionId: txnId)))
            }
        }
    }

    func createInvoice(
        apiBase: String,
        token: String,
        toCzedrId: String,
        amountDollars: String,
        description: String,
        pin: String,
        completion: @escaping (APIResult<String>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        if token.isEmpty {
            completion(.err("Not signed in"))
            return
        }
        guard let amount = CzedrMoney.parseDollarAmount(amountDollars) else {
            completion(.err("Enter a valid amount"))
            return
        }
        let body: [String: Any] = [
            "to_czedr_id": toCzedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            "rec_czedr_id": toCzedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            "amount": amount,
            "desc": description.isEmpty ? "Invoice" : description,
            "description": description.isEmpty ? "Invoice" : description,
            "user_pin": pin,
        ]
        postJSON(base: base, path: "/v1/invoices", body: body, token: token) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                if let msgs = data["msg"] as? [String], let first = msgs.first {
                    completion(.ok(first))
                } else {
                    completion(.ok("Invoice sent"))
                }
            }
        }
    }

    func fetchFundingStatus(
        apiBase: String,
        token: String,
        completion: @escaping (APIResult<(message: String, banks: [BankLinkRow])>) -> Void
    ) {
        authedGetObject(
            base: apiBase,
            path: "/v1/funding/status",
            token: token,
            map: { data in
                let msg = data["user_message"] as? String ?? ""
                let banksRaw = data["banks"] as? [[String: Any]] ?? []
                let banks = banksRaw.compactMap { row -> BankLinkRow? in
                    guard let id = row["id"] as? String else { return nil }
                    return BankLinkRow(
                        id: id,
                        last4: row["last4"] as? String ?? "",
                        accountType: row["account_type"] as? String ?? "checking",
                        status: row["status"] as? String ?? ""
                    )
                }
                return .ok((msg, banks))
            },
            completion: completion
        )
    }

    func startBankLink(
        apiBase: String,
        token: String,
        routing: String,
        account: String,
        holderName: String,
        accountType: String,
        completion: @escaping (APIResult<BankLinkStartResult>) -> Void
    ) {
        let body: [String: Any] = [
            "routing_number": routing,
            "account_number": account,
            "account_holder_name": holderName,
            "account_type": accountType,
        ]
        postJSON(base: apiBase, path: "/v1/funding/bank-link/start", body: body, token: token) { result in
            switch result {
            case .err(let msg):
                completion(.err(msg))
            case .ok(let data):
                guard let id = data["bank_link_id"] as? String else {
                    completion(.err("Invalid response"))
                    return
                }
                let a = data["micro_cents_a"] as? Int ?? (data["micro_cents_a"] as? NSNumber)?.intValue
                let b = data["micro_cents_b"] as? Int ?? (data["micro_cents_b"] as? NSNumber)?.intValue
                completion(.ok(BankLinkStartResult(
                    bankLinkId: id,
                    message: data["message"] as? String ?? "Bank link started",
                    microCentsA: a,
                    microCentsB: b
                )))
            }
        }
    }

    func confirmBankLink(
        apiBase: String,
        token: String,
        bankLinkId: String,
        amount1Cents: Int,
        amount2Cents: Int,
        completion: @escaping (APIResult<Void>) -> Void
    ) {
        let body: [String: Any] = [
            "bank_link_id": bankLinkId,
            "amount_1_cents": amount1Cents,
            "amount_2_cents": amount2Cents,
        ]
        postJSON(base: apiBase, path: "/v1/funding/bank-link/confirm", body: body, token: token) { result in
            switch result {
            case .err(let msg): completion(.err(msg))
            case .ok: completion(.ok(()))
            }
        }
    }

    func fetchReferralEarnings(
        apiBase: String,
        token: String,
        recentLimit: Int = 25,
        completion: @escaping (APIResult<ReferralEarnings>) -> Void
    ) {
        authedGetObject(
            base: apiBase,
            path: "/v1/referrals/earnings?recent_limit=\(max(1, min(recentLimit, 100)))",
            token: token,
            map: { data in
                let recentRaw = data["recent_credits"] as? [[String: Any]] ?? []
                let recent = recentRaw.compactMap { row -> ReferralCredit? in
                    let id = (row["id"] as? String) ?? ""
                    if id.isEmpty { return nil }
                    return ReferralCredit(
                        id: id,
                        amountCents: Self.int64(row["amount_cents"]),
                        createdAt: row["created_at"] as? String ?? "",
                        memo: row["memo"] as? String ?? ""
                    )
                }
                return .ok(ReferralEarnings(
                    totalCents: Self.int64(data["referral_earnings_total_cents"]),
                    paymentCount: Int(Self.int64(data["referral_payment_count"])),
                    currency: data["currency"] as? String ?? "USD",
                    recent: recent
                ))
            },
            completion: completion
        )
    }

    func fetchInvoicesSent(
        apiBase: String,
        token: String,
        completion: @escaping (APIResult<[InvoiceRow]>) -> Void
    ) {
        authedGetList(
            base: apiBase,
            path: "/v1/invoices/sent?offset=1&limit=50",
            token: token,
            map: { rows in .ok(Self.mapInvoiceRows(rows, direction: "sent")) },
            completion: completion
        )
    }

    func fetchInvoicesReceived(
        apiBase: String,
        token: String,
        completion: @escaping (APIResult<[InvoiceRow]>) -> Void
    ) {
        authedGetList(
            base: apiBase,
            path: "/v1/invoices/received?offset=1&limit=50",
            token: token,
            map: { rows in .ok(Self.mapInvoiceRows(rows, direction: "received")) },
            completion: completion
        )
    }

    func fetchHistory(apiBase: String, token: String, completion: @escaping (APIResult<[TransferRow]>) -> Void) {
        authedGetObject(
            base: apiBase,
            path: "/v1/transfers/history",
            token: token,
            map: { data in
                let rows = data["transactions"] as? [[String: Any]] ?? []
                let mapped = rows.compactMap { row -> TransferRow? in
                    let id = (row["id"] as? String) ?? (row["id"] as? NSNumber)?.stringValue
                    guard let id = id, !id.isEmpty else { return nil }
                    return TransferRow(
                        id: id,
                        amountCents: Self.int64(row["amount_cents"]),
                        currency: row["currency"] as? String ?? "USD",
                        memo: row["memo"] as? String ?? "",
                        createdAt: row["created_at"] as? String ?? "",
                        fromCzedrId: row["from_czedr_id"] as? String ?? "",
                        toCzedrId: row["to_czedr_id"] as? String ?? "",
                        status: row["status"] as? String ?? ""
                    )
                }
                return .ok(mapped)
            },
            completion: completion
        )
    }

    private static func mapInvoiceRows(_ rows: [[String: Any]], direction: String) -> [InvoiceRow] {
        rows.compactMap { row -> InvoiceRow? in
            let id = (row["id"] as? String) ?? ""
            if id.isEmpty { return nil }
            let cid = (row["user_id"] as? String) ?? ""
            let label = (row["name"] as? String) ?? (row["user_email"] as? String) ?? cid
            let amountStr = row["amount"] as? String ?? (row["amount"] as? NSNumber)?.stringValue ?? "0"
            let dollars = Double(amountStr) ?? 0
            let cents = Int64((dollars * 100.0).rounded())
            return InvoiceRow(
                id: id,
                counterpartyCzedrId: cid,
                counterpartyLabel: label,
                amountCents: cents,
                description: row["description"] as? String ?? "",
                createdAt: row["created_date"] as? String ?? "",
                direction: direction
            )
        }
    }

    // MARK: - HTTP helpers

    private func authedGetList<T>(
        base: String,
        path: String,
        token: String,
        map: @escaping ([[String: Any]]) -> APIResult<T>,
        completion: @escaping (APIResult<T>) -> Void
    ) {
        guard let base = Self.normalizeBase(apiBase) else {
            completion(.err("Invalid API base URL"))
            return
        }
        if token.isEmpty {
            completion(.err("Not signed in"))
            return
        }
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        run(req) { result in
            switch result {
            case .failure(let err):
                completion(.err(Self.friendlyNetworkError(err)))
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.err("Invalid JSON"))
                    return
                }
                if json["Status"] as? String != "true" {
                    completion(.err(Self.errorMessage(from: data) ?? "Request failed"))
                    return
                }
                let payload = json["Data"]
                let rows: [[String: Any]]
                if let arr = payload as? [[String: Any]] {
                    rows = arr
                } else {
                    rows = []
                }
                completion(map(rows))
            }
        }
    }

    private func authedGetObject<T>(
        base: String,
        path: String,
        token: String,
        map: @escaping ([String: Any]) -> APIResult<T>,
        completion: @escaping (APIResult<T>) -> Void
    ) {
        guard let base = Self.normalizeBase(base) else {
            completion(.err("Invalid API base URL"))
            return
        }
        if token.isEmpty {
            completion(.err("Not signed in"))
            return
        }
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        run(req) { self.parseEnvelope($0, map: map, completion: completion) }
    }

    private func postJSON(
        base: String,
        path: String,
        body: [String: Any],
        token: String?,
        completion: @escaping (APIResult<[String: Any]>) -> Void
    ) {
        guard let url = URL(string: "\(base)\(path)") else {
            completion(.err("Invalid URL"))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let token, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        run(req) { self.parseEnvelope($0, map: { .ok($0) }, completion: completion) }
    }

    private func run(_ req: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        session.dataTask(with: req) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "CzedrAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"])))
                return
            }
            let raw = data ?? Data()
            if !(200 ..< 300).contains(http.statusCode) {
                let msg = Self.errorMessage(from: raw) ?? "HTTP \(http.statusCode)"
                completion(.failure(NSError(domain: "CzedrAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            completion(.success(raw))
        }.resume()
    }

    private func parseEnvelope<T>(
        _ result: Result<Data, Error>,
        map: @escaping ([String: Any]) -> APIResult<T>,
        completion: @escaping (APIResult<T>) -> Void
    ) {
        switch result {
        case .failure(let err):
            completion(.err(Self.friendlyNetworkError(err)))
        case .success(let data):
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.err("Invalid JSON"))
                return
            }
            if json["Status"] as? String != "true" {
                completion(.err(Self.errorMessage(from: data) ?? "Request failed"))
                return
            }
            let payload = json["Data"]
            if let obj = payload as? [String: Any] {
                completion(map(obj))
            } else if let arr = payload as? [[String: Any]], let first = arr.first {
                completion(map(first))
            } else if let arr = payload as? [Any], let first = arr.first as? [String: Any] {
                completion(map(first))
            } else {
                completion(.err("Unexpected response shape"))
            }
        }
    }

    private static func normalizeBase(_ url: String) -> String? {
        var u = url.trimmingCharacters(in: .whitespacesAndNewlines)
        while u.hasSuffix("/") { u.removeLast() }
        guard !u.isEmpty, let components = URLComponents(string: u), let host = components.host else { return nil }
        let scheme = components.scheme ?? "http"
        if let port = components.port, port != (scheme == "https" ? 443 : 80) {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let dataArr = json["Data"] as? [[String: Any]], let first = dataArr.first {
            return (first["result"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        return (json["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func int64(_ value: Any?) -> Int64 {
        if let n = value as? Int64 { return n }
        if let n = value as? Int { return Int64(n) }
        if let n = value as? NSNumber { return n.int64Value }
        if let s = value as? String, let n = Int64(s) { return n }
        return 0
    }

    private static func friendlyNetworkError(_ err: Error) -> String {
        let ns = err as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut,
                 NSURLErrorCannotFindHost:
                return "Cannot reach Czedr. Check your internet connection and try again."
            default:
                break
            }
        }
        let msg = err.localizedDescription
        if msg.localizedCaseInsensitiveContains("connect") {
            return "Cannot reach Czedr. Check your internet connection and try again."
        }
        return msg
    }
}
