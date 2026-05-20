//
//  CzedrSwiftBootstrap.swift
//  Obj-C entry via CzedrSwiftLauncher.m
//

import SwiftUI
import UIKit

@objc public final class CzedrSwiftBootstrap: NSObject {
    private static let session = AppSession()

    /// Force-quit then reopen must show sign-in (matches legacy clearLocalSession on launch).
    @objc public static func clearSessionOnColdLaunch() {
        KeychainStore.clearSession()
        session.resetToLoggedOut()
    }

    @objc public static func present(in window: UIWindow) {
        let root = UIHostingController(
            rootView: CzedrSwiftRootView().environmentObject(session)
        )
        root.view.backgroundColor = UIColor(
            red: 42 / 255,
            green: 42 / 255,
            blue: 44 / 255,
            alpha: 1
        )
        window.rootViewController = root
    }
}
