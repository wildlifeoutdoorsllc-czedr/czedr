//
//  CzedrPaymentQrView.swift
//  Profile "My payment QR" card with reliable regeneration when Czedr ID is known.
//

import SwiftUI
import UIKit

struct CzedrPaymentQrView: View {
    let czedrId: String

    @State private var qrImage: UIImage?

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
    }

    private func refreshQr() {
        let id = czedrId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            qrImage = nil
            return
        }
        qrImage = CzedrQrCode.image(from: CzedrQrCode.paymentPayload(czedrId: id))
    }
}
