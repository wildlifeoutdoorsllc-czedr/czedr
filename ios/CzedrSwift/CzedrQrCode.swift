//
//  CzedrQrCode.swift
//  Generate payment QR images and parse Czedr IDs from scans, URLs, or pasted text.
//

import UIKit
import CoreImage.CIFilterBuiltins

enum CzedrQrCode {
    /// Payload encoded in member payment QR codes.
    static let payUrlPrefix = "https://czedr.com/pay/"

    private static let idPattern = try? NSRegularExpression(pattern: #"(?i)\b(CZ[0-9A-F]{8})\b"#)

    static func paymentPayload(czedrId: String) -> String {
        let id = czedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return payUrlPrefix + id
    }

    static func image(from string: String, dimension: CGFloat = 220) -> UIImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scale = dimension / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Finds a Czedr ID in a QR string, URL, or plain text (e.g. pasted from Messages).
    static func parseCzedrId(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        if let id = firstIdMatch(in: trimmed) { return id }

        if let url = URL(string: trimmed), let host = url.host?.lowercased() {
            if host.contains("czedr.com") {
                let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if let id = firstIdMatch(in: path) { return id }
            }
            if url.scheme?.lowercased() == "czedr" {
                if let item = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name.lowercased() == "czedr_id" })?
                    .value,
                   let id = firstIdMatch(in: item) {
                    return id
                }
            }
        }

        return firstIdMatch(in: trimmed.replacingOccurrences(of: "-", with: ""))
    }

    private static func firstIdMatch(in text: String) -> String? {
        guard let idPattern else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = idPattern.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[r]).uppercased()
    }
}
