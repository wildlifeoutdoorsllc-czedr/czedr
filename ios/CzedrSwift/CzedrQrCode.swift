//
//  CzedrQrCode.swift
//  Generate payment QR images and parse Czedr IDs from scans, URLs, or pasted text.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum CzedrQrCode {
    /// Payload encoded in member payment QR codes.
    static let payUrlPrefix = "https://czedr.com/pay/"

    private static let idPattern = try? NSRegularExpression(pattern: #"(?i)\b(CZ[0-9A-F]{8})\b"#)
    private static let ciContext = CIContext(options: nil)

    static func paymentPayload(czedrId: String) -> String {
        let id = czedrId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return payUrlPrefix + id
    }

    /// Renders a scannable black-on-white QR at the given point size.
    static func image(from string: String, dimension: CGFloat = 220) -> UIImage? {
        let payload = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard var ciImage = filter.outputImage else { return nil }

        // CIQRCodeGenerator often returns a tiny image with a non-zero origin — scale and normalize.
        let extent = ciImage.extent
        let side = max(extent.width, extent.height, 1)
        let scale = dimension / side
        ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let normalized = ciImage.transformed(
            by: CGAffineTransform(translationX: -ciImage.extent.origin.x, y: -ciImage.extent.origin.y)
        )

        let size = CGSize(width: dimension, height: dimension)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let drawRect = CGRect(origin: .zero, size: size)
            let cgContext = ctx.cgContext
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: 1, y: -1)
            ciContext.draw(normalized, in: drawRect, from: normalized.extent)
        }
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
