//
//  CzedrPaymentQrView.swift
//  "My payment QR" card — shown on Referral Earnings; regenerates when Czedr ID or payload changes.
//

import SwiftUI
import UIKit

struct CzedrPaymentQrView: View {
    let czedrId: String
    var paymentQrPayload: String = ""
    @Environment(\.czedrTextSize) private var textSize

    @State private var qrImage: UIImage?
    @State private var qrFailed = false

    var body: some View {
        VStack(spacing: 12) {
            Text("My payment QR")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .accessibilityLabel("Payment QR code for \(czedrId)")
                } else if qrFailed {
                    VStack(spacing: 6) {
                        Image(systemName: "qrcode")
                            .font(.system(size: CzedrTypography.scaled(48, size: textSize)))
                            .foregroundColor(CzedrPalette.caption)
                        Text("QR could not be drawn on this device.")
                            .font(.caption)
                            .foregroundColor(CzedrPalette.caption)
                            .multilineTextAlignment(.center)
                        Text("Others can still pay you using your ID below.")
                            .font(.caption2)
                            .foregroundColor(CzedrPalette.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 200, height: 200)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: CzedrPalette.cheddarGold))
                        Text("Generating QR…")
                            .font(.caption)
                            .foregroundColor(CzedrPalette.caption)
                    }
                    .frame(width: 200, height: 200)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity)

            Text("Show this so others can pay you. They can also type or paste your ID: \(czedrId)")
                .font(.caption)
                .foregroundColor(CzedrPalette.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .onAppear(perform: refreshQr)
        .onChange(of: czedrId, perform: { _ in refreshQr() })
        .onChange(of: paymentQrPayload, perform: { _ in refreshQr() })
    }

    private func refreshQr() {
        let id = czedrId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            qrImage = nil
            qrFailed = false
            return
        }
        let trimmedPayload = paymentQrPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = trimmedPayload.isEmpty ? CzedrQrCode.paymentPayload(czedrId: id) : trimmedPayload
        if let image = CzedrQrCode.image(from: payload) {
            qrImage = image
            qrFailed = false
        } else {
            qrImage = nil
            qrFailed = true
        }
    }
}
