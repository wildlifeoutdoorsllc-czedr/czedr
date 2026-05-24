//
//  CzedrMenuButton.swift
//  UIKit menu button — reliable taps on home (SwiftUI Button can fail under NavigationView).
//

import SwiftUI
import UIKit

struct CzedrMenuBarButton: UIViewRepresentable {
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "line.3.horizontal", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(
            red: 231 / 255,
            green: 236 / 255,
            blue: 243 / 255,
            alpha: 1
        )
        button.accessibilityLabel = "Menu"
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.onTap = onTap
    }

    final class Coordinator: NSObject {
        var onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func tapped() {
            onTap()
        }
    }
}
