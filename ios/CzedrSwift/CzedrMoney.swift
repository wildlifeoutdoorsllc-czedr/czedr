//
//  CzedrMoney.swift
//  US currency display (comma thousands separator).
//

import Foundation

enum CzedrMoney {
    private static let usCurrency: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// e.g. $10,193.71 (USD) or $10,193.71 EUR
    static func format(cents: Int64, currency: String = "USD") -> String {
        let dollars = Double(cents) / 100.0
        let code = currency.isEmpty ? "USD" : currency
        let formatter = usCurrency
        if code == "USD" {
            return formatter.string(from: NSNumber(value: dollars)) ?? fallback(dollars: dollars, currency: code)
        }
        let decimal = NumberFormatter()
        decimal.locale = Locale(identifier: "en_US")
        decimal.numberStyle = .decimal
        decimal.minimumFractionDigits = 2
        decimal.maximumFractionDigits = 2
        let amount = decimal.string(from: NSNumber(value: dollars)) ?? String(format: "%.2f", dollars)
        return "$\(amount) \(code)"
    }

    static func parseDollarsToCents(_ input: String) -> Int64? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return Int64((value * 100.0).rounded())
    }

    private static func fallback(dollars: Double, currency: String) -> String {
        String(format: "$%.2f %@", dollars, currency)
    }
}
