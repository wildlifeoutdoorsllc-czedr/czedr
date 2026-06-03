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

    private static let usDecimal: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.generatesDecimalNumbers = true
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

    /// Parses dollar input: `15`, `15.`, `15.5`, `15.00`, `$15`, `1,234.56` → dollars (not cents).
    static func parseDollarAmount(_ input: String) -> Double? {
        var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty { return nil }

        // Whole dollars only (e.g. "15" → $15.00).
        if cleaned.allSatisfy(\.isNumber) {
            return Double(cleaned).flatMap { $0 > 0 ? $0 : nil }
        }

        // Decimal comma when no dot: "15,5" / "15,50" (not thousands).
        if cleaned.contains(","), !cleaned.contains(".") {
            if let comma = cleaned.lastIndex(of: ",") {
                let after = cleaned[cleaned.index(after: comma)...]
                if !after.isEmpty, after.count <= 2, after.allSatisfy(\.isNumber) {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
                } else {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: "")
                }
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        }

        while cleaned.hasSuffix(".") {
            cleaned.removeLast()
        }
        if cleaned.isEmpty { return nil }

        if let n = usDecimal.number(from: cleaned) as? NSDecimalNumber {
            let value = n.doubleValue
            return value > 0 ? value : nil
        }
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    static func parseDollarsToCents(_ input: String) -> Int64? {
        guard let dollars = parseDollarAmount(input) else { return nil }
        return Int64((dollars * 100.0).rounded())
    }

    private static func fallback(dollars: Double, currency: String) -> String {
        String(format: "$%.2f %@", dollars, currency)
    }
}
