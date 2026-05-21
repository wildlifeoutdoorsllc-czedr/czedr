//
//  CzedrSwiftRootView.swift
//  SwiftUI shell — login, home, payments, history, profile
//

import SwiftUI

// MARK: - Root

struct CzedrSwiftRootView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        Group {
            if session.isLoggedIn {
                LoggedInNavigationView()
            } else {
                AuthGateView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Auth (sign-in / sign-up)

struct AuthGateView: View {
    @State private var showSignUp = false

    var body: some View {
        Group {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                LoginView(showSignUp: $showSignUp)
            }
        }
    }
}

struct LoginView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var session: AppSession
    @State private var email = ""
    @State private var password = ""
    @State private var apiBase = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CzedrBrandLogoView(style: .signIn)
                    .padding(.top, 32)

                Text(session.buildLabel)
                    .font(.caption)
                    .foregroundColor(CzedrPalette.caption)

                field("API base URL", text: $apiBase, keyboard: .URL)
                    .onAppear { if apiBase.isEmpty { apiBase = session.defaultApiBase() } }
                field("Email", text: $email, keyboard: .emailAddress)
                field("Password", text: $password, secure: true)

                if let err = session.errorMessage {
                    Text(err).font(.footnote).foregroundColor(CzedrPalette.redPrimary)
                }

                Button(action: signIn) {
                    Text(session.isLoading ? "Signing in…" : "Sign in")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CzedrPalette.charcoalButton)
                        .foregroundColor(CzedrPalette.lightText)
                        .cornerRadius(6)
                }
                .disabled(session.isLoading)

                Button(action: { showSignUp = true }) {
                    Text("Create account")
                        .font(.subheadline)
                        .foregroundColor(CzedrPalette.caption)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(CzedrPalette.background.edgesIgnoringSafeArea(.all))
    }

    private func signIn() {
        session.clearError()
        session.login(email: email, password: password, apiBaseOverride: apiBase)
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(CzedrPalette.caption)
            if secure {
                CzedrPlaceholderSecureField(placeholder: label, text: text, keyboard: keyboard)
            } else {
                CzedrPlaceholderTextField(placeholder: label, text: text, keyboard: keyboard)
            }
        }
    }
}

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var session: AppSession
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var referrerCzedrId = ""
    @State private var apiBase = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CzedrBrandLogoView(style: .signIn)
                    .padding(.top, 24)

                Text("Create your Czedr account")
                    .font(.headline)
                    .foregroundColor(CzedrPalette.lightText)

                Text(session.buildLabel)
                    .font(.caption)
                    .foregroundColor(CzedrPalette.caption)

                field("API base URL", text: $apiBase, keyboard: .URL)
                    .onAppear { if apiBase.isEmpty { apiBase = session.defaultApiBase() } }
                field("Email", text: $email, keyboard: .emailAddress)
                field("Password (10+ characters)", text: $password, secure: true)
                field("Confirm password", text: $confirmPassword, secure: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Referrer Czedr ID (optional)")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                    CzedrPlaceholderTextField(
                        placeholder: "Who invited you?",
                        text: $referrerCzedrId,
                        autocapitalization: .allCharacters
                    )
                    Text("Leave blank if no one referred you. Each referred member can earn their referrer $0.17 when they send or receive payments.")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                }

                if let err = session.errorMessage {
                    Text(err).font(.footnote).foregroundColor(CzedrPalette.redPrimary)
                }

                Button(action: signUp) {
                    Text(session.isLoading ? "Creating account…" : "Sign up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CzedrPalette.redPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .disabled(session.isLoading)

                Button(action: { showSignUp = false; session.clearError() }) {
                    Text("Already have an account? Sign in")
                        .font(.subheadline)
                        .foregroundColor(CzedrPalette.caption)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(CzedrPalette.background.edgesIgnoringSafeArea(.all))
    }

    private func signUp() {
        session.clearError()
        if password != confirmPassword {
            session.errorMessage = "Passwords do not match"
            return
        }
        if password.count < 10 {
            session.errorMessage = "Password must be at least 10 characters"
            return
        }
        session.register(
            email: email,
            password: password,
            referrerCzedrId: referrerCzedrId,
            apiBaseOverride: apiBase
        )
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(CzedrPalette.caption)
            if secure {
                CzedrPlaceholderSecureField(placeholder: label, text: text, keyboard: keyboard)
            } else {
                CzedrPlaceholderTextField(placeholder: label, text: text, keyboard: keyboard)
            }
        }
    }
}

/// Legacy style for fields not using `CzedrPlaceholderTextField` — prefer that helper.
struct CzedrFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .foregroundColor(CzedrPalette.fieldText)
            .background(CzedrPalette.orangeField)
            .cornerRadius(4)
    }
}

// MARK: - Logged-in navigation

struct LoggedInNavigationView: View {
    @EnvironmentObject var session: AppSession
    @State private var showMenu = false

    var body: some View {
        NavigationView {
            HomeScreen(showMenu: $showMenu)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showMenu) {
            MenuSheet(showMenu: $showMenu)
                .environmentObject(session)
        }
    }
}

struct MenuSheet: View {
    @Binding var showMenu: Bool
    @EnvironmentObject var session: AppSession

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HomeScreen(showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Home")
                }
                NavigationLink(destination: MakePaymentScreen(showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Make Payment")
                }
                NavigationLink(destination: HistoryScreen(showMenu: $showMenu, openedFromMenu: true)) {
                    Text("History")
                }
                NavigationLink(destination: ProfileScreen(showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Profile")
                }
                NavigationLink(destination: SendInvoiceScreen(showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Send Invoice")
                }
                NavigationLink(destination: PlaceholderScreen(title: "Pending Invoices", showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Pending Invoices")
                }
                NavigationLink(destination: PlaceholderScreen(title: "Link Card", showMenu: $showMenu, openedFromMenu: true)) {
                    Text("Link Card")
                }
            }
            .navigationBarTitle("Menu", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { showMenu = false })
        }
    }
}

// MARK: - Screen chrome (one toolbar + one logo per screen)

/// Top bar only — logo lives in page body, not duplicated in the toolbar.
struct ShellToolbar: View {
    let title: String
    var showBack: Bool = true
    var onMenu: (() -> Void)?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { onMenu?() }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title)
                        .foregroundColor(CzedrPalette.lightText)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                if showBack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(CzedrPalette.lightText)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(CzedrPalette.surface)

            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CzedrPalette.lightText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(CzedrPalette.surface)
            }
        }
    }
}

/// Standard logged-in page: single toolbar, single hero logo, then content.
struct LoggedInPageLayout<Content: View>: View {
    let title: String
    var showBack: Bool = true
    var onMenu: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ShellToolbar(title: title, showBack: showBack, onMenu: onMenu)
            CzedrBrandLogoView(style: .hero)
                .padding(.bottom, 4)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(CzedrPalette.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}

// MARK: - Home

struct HomeScreen: View {
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession

    private var openMenu: () -> Void { { showMenu = true } }

    var body: some View {
        LoggedInPageLayout(title: "", showBack: openedFromMenu, onMenu: openMenu) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(session.czedrId)
                            .font(.subheadline)
                            .foregroundColor(CzedrPalette.caption)
                            .multilineTextAlignment(.center)
                        Text(session.buildLabel)
                            .font(.caption)
                            .foregroundColor(CzedrPalette.caption)
                            .multilineTextAlignment(.center)

                        Text("Available balance")
                            .font(.caption)
                            .foregroundColor(CzedrPalette.caption)
                            .multilineTextAlignment(.center)
                        Text(session.balanceText)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(CzedrPalette.balanceGreen)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    if let msg = session.actionMessage {
                        HStack {
                            Text(msg).foregroundColor(CzedrPalette.balanceGreen)
                            Spacer()
                            Button("OK") { session.actionMessage = nil }
                                .foregroundColor(CzedrPalette.caption)
                        }
                    }
                    if let err = session.errorMessage {
                        Text(err).font(.footnote).foregroundColor(CzedrPalette.redPrimary)
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            NavigationLink(destination: MakePaymentScreen(showMenu: $showMenu)) {
                                tileContent("Make Payment", "dollarsign.circle")
                            }
                            NavigationLink(destination: SendInvoiceScreen(showMenu: $showMenu)) {
                                tileContent("Send Invoice", "doc.text")
                            }
                        }
                        HStack(spacing: 12) {
                            NavigationLink(destination: PlaceholderScreen(title: "Pending Invoices", showMenu: $showMenu)) {
                                tileContent("Pending", "clock")
                            }
                            NavigationLink(destination: HistoryScreen(showMenu: $showMenu)) {
                                tileContent("History", "list.bullet")
                            }
                        }
                    }

                    NavigationLink(destination: ProfileScreen(showMenu: $showMenu)) {
                        Text("My Profile")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear { session.refreshBalance() }
    }

    private func tileContent(_ title: String, _ symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title)
            Text(title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
        }
        .foregroundColor(CzedrPalette.lightText)
        .frame(maxWidth: .infinity, minHeight: 88)
        .background(CzedrPalette.gridTile)
        .cornerRadius(8)
    }
}

// MARK: - Make Payment

struct MakePaymentScreen: View {
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @State private var recipientId = ""
    @State private var validatedName = ""
    @State private var amount = ""
    @State private var memo = ""
    @State private var pin = ""

    var body: some View {
        LoggedInPageLayout(title: "Make Payment", showBack: true, onMenu: { showMenu = true }) {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        CzedrPlaceholderTextField(
                            placeholder: "Recipient Czedr ID",
                            text: $recipientId,
                            autocapitalization: .allCharacters
                        )
                        Button("VALIDATE") { validate() }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .background(CzedrPalette.redPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    if !validatedName.isEmpty {
                        Text(validatedName).font(.footnote).foregroundColor(CzedrPalette.balanceGreen)
                    }
                    CzedrPlaceholderTextField(
                        placeholder: "Enter amount",
                        text: $amount,
                        keyboard: .decimalPad
                    )
                    .frame(minHeight: 56)

                    CzedrPlaceholderTextField(placeholder: "Description", text: $memo)

                    CzedrPinEntryView(pin: $pin)
                        .padding(.top, 12)

                    Button(action: pay) {
                        Text(session.isLoading ? "…" : "MAKE PAYMENT")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                    .disabled(session.isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func validate() {
        session.clearError()
        session.validateRecipient(recipientId) { name in
            validatedName = name ?? ""
        }
    }

    private func pay() {
        session.clearError()
        session.sendTransfer(to: recipientId, amountDollars: amount, memo: memo, pin: pin)
    }
}

// MARK: - History

struct HistoryScreen: View {
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession
    @State private var rows: [TransferRow] = []

    var body: some View {
        LoggedInPageLayout(title: "History", showBack: true, onMenu: { showMenu = true }) {
            List(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppSession.formatMoney(cents: row.amountCents, currency: row.currency))
                        .font(.headline)
                        .foregroundColor(CzedrPalette.balanceGreen)
                    Text(row.memo).foregroundColor(CzedrPalette.lightText)
                    Text("\(row.fromCzedrId) → \(row.toCzedrId)")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                    Text(row.createdAt).font(.caption).foregroundColor(CzedrPalette.caption)
                }
                .listRowBackground(CzedrPalette.surface)
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        session.fetchHistory { rows = $0 }
    }
}

// MARK: - Profile

struct ProfileScreen: View {
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false
    @EnvironmentObject var session: AppSession

    var body: some View {
        LoggedInPageLayout(title: "Profile", showBack: true, onMenu: { showMenu = true }) {
            VStack(alignment: .leading, spacing: 16) {
                row("Email", session.email)
                row("Czedr ID", session.czedrId)
                row("API", session.apiBase)
                row("Build", session.buildLabel)
                Spacer()
                Button(action: { session.logout() }) {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CzedrPalette.redPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .padding(16)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(CzedrPalette.caption)
            Text(value).foregroundColor(CzedrPalette.lightText)
        }
    }
}

struct PlaceholderScreen: View {
    let title: String
    @Binding var showMenu: Bool
    var openedFromMenu: Bool = false

    var body: some View {
        LoggedInPageLayout(title: title, showBack: true, onMenu: { showMenu = true }) {
            Text("Coming in the next SwiftUI sprint")
                .foregroundColor(CzedrPalette.caption)
                .padding(16)
            Spacer()
        }
    }
}
