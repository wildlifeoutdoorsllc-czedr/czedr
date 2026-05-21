//
//  CzedrFormFields.swift
//  Orange fields with charcoal placeholder text (not white).
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
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(CzedrPalette.fieldPlaceholder)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(false)
            }
            TextField("", text: $text)
                .keyboardType(keyboard)
                .autocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
                .textFieldStyle(CzedrFieldStyle())
        }
    }
}

struct CzedrPlaceholderSecureField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(CzedrPalette.fieldPlaceholder)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(false)
            }
            SecureField("", text: $text)
                .keyboardType(keyboard)
                .textFieldStyle(CzedrFieldStyle())
        }
    }
}
