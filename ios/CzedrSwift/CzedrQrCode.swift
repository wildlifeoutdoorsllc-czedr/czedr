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

        // CIQRCodeGenerator returns a tiny image — scale up before rasterizing.
        let extent = ciImage.extent
        let side = max(extent.width, extent.height, 1)
        let scale = dimension / side
        ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let normalized = ciImage.transformed(
            by: CGAffineTransform(translationX: -ciImage.extent.origin.x, y: -ciImage.extent.origin.y)
        )

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = normalized
        colorFilter.color0 = CIColor(color: .black)
        colorFilter.color1 = CIColor(color: .white)
        guard let colored = colorFilter.outputImage else { return nil }

        let drawRect = colored.extent.integral
        guard drawRect.width > 1, drawRect.height > 1,
              let cgImage = ciContext.createCGImage(colored, from: drawRect) else {
            return nil
        }

        let scaleFactor = UIScreen.main.scale
        let uiImage = UIImage(cgImage: cgImage, scale: scaleFactor, orientation: .up)
        return isLikelyBlank(uiImage) ? nil : uiImage
    }

    /// True when the QR bitmap has no dark modules (failed Core Image draw on device).
    static func isLikelyBlank(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return true }
        let w = min(cgImage.width, 64)
        let h = min(cgImage.height, 64)
        guard w > 0, h > 0 else { return true }

        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return true }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        var darkCount = 0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let lum = (Int(pixels[i]) + Int(pixels[i + 1]) + Int(pixels[i + 2])) / 3
            if lum < 200 { darkCount += 1 }
        }
        return darkCount < 12
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
