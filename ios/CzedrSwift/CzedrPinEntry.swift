//
//  CzedrPinEntry.swift
//  4-digit PIN — vertical red slots (legacy Make Payment design).
//

import SwiftUI

/// Shared PIN UI: red label + four tall vertical red boxes; hidden numeric field captures input.
struct CzedrPinEntryView: View {
    @Binding var pin: String
    var label: String = "ENTER YOUR CZEDR PIN"
    private let length = 4

    private var sanitizedPin: Binding<String> {
        Binding(
            get: { pin },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                pin = String(digits.prefix(length))
            }
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(CzedrPalette.redPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ZStack {
                HStack(spacing: 18) {
                    ForEach(0..<length, id: \.self) { index in
                        pinSlot(filled: index < pin.count)
                    }
                }
                .frame(maxWidth: .infinity)

                TextField("", text: sanitizedPin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .opacity(0.02)
                    .accentColor(.clear)
                    .foregroundColor(.clear)
            }
            .frame(height: 80)
        }
        .padding(.vertical, 4)
    }

    private func pinSlot(filled: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(CzedrPalette.redPrimary)
                .frame(width: 42, height: 76)
            if filled {
                Text("•")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -2)
            }
        }
        .accessibilityLabel(filled ? "PIN digit entered" : "PIN digit empty")
    }
}
