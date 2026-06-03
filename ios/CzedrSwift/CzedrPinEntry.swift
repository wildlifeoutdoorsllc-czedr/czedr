//
//  CzedrPinEntry.swift
//  4-digit PIN — vertical red slots (legacy Make Payment design).
//

import SwiftUI
import UIKit

/// UIKit tag so tap-to-dismiss keyboard does not steal touches from PIN entry.
enum CzedrPinEntryTag {
    static func container(fieldId: Int) -> Int {
        0xC2ED_0000 + fieldId
    }
}

/// Shared PIN UI: red label + four tall vertical red boxes; UIKit field captures digits reliably.
struct CzedrPinEntryView: View {
    @Binding var pin: String
    var label: String = "ENTER YOUR CZEDR PIN"
    var fieldId: Int = 0
    @Environment(\.czedrTextSize) private var textSize
    private let length = 4

    var body: some View {
        VStack(spacing: 14) {
            Text(label)
                .font(.system(size: CzedrTypography.scaled(17, size: textSize), weight: .bold))
                .foregroundColor(CzedrPalette.redPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ZStack {
                HStack(spacing: 18) {
                    ForEach(0..<length, id: \.self) { index in
                        pinSlot(filled: index < pin.count)
                    }
                }
                .allowsHitTesting(false)

                CzedrPinCaptureField(text: $pin, maxLength: length, fieldId: fieldId)
                    .frame(maxWidth: .infinity)
                    .frame(height: slotH)
            }
            .frame(height: slotH)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
    }

    private func pinSlot(filled: Bool) -> some View {
        let slotW = CzedrTypography.scaled(48, size: textSize)
        let slotH = CzedrTypography.scaled(84, size: textSize)
        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(CzedrPalette.redPrimary)
                .frame(width: slotW, height: slotH)
            if filled {
                Text("•")
                    .font(.system(size: CzedrTypography.scaled(42, size: textSize), weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -2)
            }
        }
        .accessibilityLabel(filled ? "PIN digit entered" : "PIN digit empty")
    }
}

// MARK: - UIKit PIN capture (reliable focus + number pad on device)

private struct CzedrPinCaptureField: UIViewRepresentable {
    @Binding var text: String
    let maxLength: Int
    let fieldId: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let tag = CzedrPinEntryTag.container(fieldId: fieldId)
        let container = UIView()
        container.tag = tag
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = true

        let field = UITextField()
        field.tag = tag
        field.translatesAutoresizingMaskIntoConstraints = false
        field.keyboardType = .numberPad
        // No global ✕ accessory bar — it renders as a floating white bubble beside the number pad.
        field.inputAccessoryView = nil
        field.textContentType = .oneTimeCode
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.textColor = .clear
        field.tintColor = .clear
        field.backgroundColor = .clear
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged), for: .editingChanged)

        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.focusField))
        container.addGestureRecognizer(tap)
        context.coordinator.textField = field

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let field = context.coordinator.textField else { return }
        if field.text != text {
            field.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CzedrPinCaptureField
        weak var textField: UITextField?

        init(parent: CzedrPinCaptureField) {
            self.parent = parent
        }

        @objc func focusField() {
            textField?.becomeFirstResponder()
        }

        @objc func editingChanged(_ field: UITextField) {
            syncFromField(field)
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = textField.text ?? ""
            guard let textRange = Range(range, in: current) else { return false }
            let proposed = current.replacingCharacters(in: textRange, with: string)
            let limited = Self.digitsOnly(proposed, max: parent.maxLength)
            textField.text = limited
            parent.text = limited
            return false
        }

        private func syncFromField(_ field: UITextField) {
            let limited = Self.digitsOnly(field.text ?? "", max: parent.maxLength)
            if field.text != limited {
                field.text = limited
            }
            parent.text = limited
        }

        private static func digitsOnly(_ raw: String, max: Int) -> String {
            let digits = raw.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
            return String(String.UnicodeScalarView(digits).prefix(max))
        }
    }
}
