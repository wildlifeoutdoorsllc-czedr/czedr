//
//  CzedrFormFields.swift
//  Orange fields — placeholder drawn on top; dark text for contrast.
//

import SwiftUI

struct CzedrPlaceholderTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .none
    var disableAutocorrection = true

    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $text)
                .keyboardType(keyboard)
                .autocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
                .padding(12)
                .foregroundColor(CzedrPalette.fieldText)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(CzedrPalette.fieldPlaceholder)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(false)
            }
        }
        .background(CzedrPalette.orangeField)
        .cornerRadius(4)
    }
}

struct CzedrPlaceholderSecureField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        ZStack(alignment: .leading) {
            SecureField("", text: $text)
                .keyboardType(keyboard)
                .padding(12)
                .foregroundColor(CzedrPalette.fieldText)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(CzedrPalette.fieldPlaceholder)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(false)
            }
        }
        .background(CzedrPalette.orangeField)
        .cornerRadius(4)
    }
}
