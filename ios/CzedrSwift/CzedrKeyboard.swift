//
//  CzedrKeyboard.swift
//  Dismiss keyboards: ✕ on accessory bar + tap outside fields.
//

import ObjectiveC
import UIKit

enum CzedrKeyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Adds a toolbar with ✕ above the keyboard (number pad, decimal pad, etc.).
    static func installGlobalAccessoryBar() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.tintColor = .white

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let close = UIBarButtonItem(
            title: "✕",
            style: .done,
            target: KeyboardDismissTarget.shared,
            action: #selector(KeyboardDismissTarget.dismissKeyboard)
        )
        close.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .semibold)], for: .normal)
        toolbar.items = [flex, close]

        UITextField.appearance().inputAccessoryView = toolbar
    }

    /// SwiftUI TextField uses UIKit underneath — keep typed text dark on orange.
    static func installFieldTextAppearance() {
        UITextField.appearance().textColor = .black
        UITextField.appearance().tintColor = UIColor(red: 231 / 255, green: 236 / 255, blue: 243 / 255, alpha: 1)
    }
}

@objc private final class KeyboardDismissTarget: NSObject {
    static let shared = KeyboardDismissTarget()

    @objc func dismissKeyboard() {
        CzedrKeyboard.dismiss()
    }
}

// MARK: - Tap outside fields (on hosting controller root view)

extension UIView {
    private static var dismissTapKey: UInt8 = 0

    func czedr_installKeyboardDismissTap() {
        if objc_getAssociatedObject(self, &UIView.dismissTapKey) != nil { return }
        let tap = UITapGestureRecognizer(target: KeyboardDismissTarget.shared, action: #selector(KeyboardDismissTarget.dismissKeyboard))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        objc_setAssociatedObject(self, &UIView.dismissTapKey, tap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
