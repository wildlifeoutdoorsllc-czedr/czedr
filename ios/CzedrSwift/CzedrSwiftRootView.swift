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
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject var session: AppSession
    @State private var email = ""
    @State private var password = ""
    @State private var apiBase = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("Czedr-auth-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 120)
                    .padding(.top, 40)

                Text("Czedr")
                    .font(.title2.bold())
                    .foregroundColor(CzedrPalette.lightText)

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
                SecureField(label, text: text)
                    .textFieldStyle(CzedrFieldStyle())
            } else {
                TextField(label, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(CzedrFieldStyle())
            }
        }
    }
}

struct CzedrFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(CzedrPalette.orangeField)
            .foregroundColor(.black)
            .cornerRadius(4)
    }
}

// MARK: - Logged-in navigation

struct LoggedInNavigationView: View {
    @EnvironmentObject var session: AppSession
    @State private var showMenu = false

    var body: some View {
        NavigationView {
            HomeView(showMenu: $showMenu)
                .navigationBarHidden(true)
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
                NavigationLink(destination: shellWrap(HomeView(showMenu: .constant(false)), title: "Home", showBack: true)) {
                    Text("Home")
                }
                NavigationLink(destination: shellWrap(MakePaymentView(), title: "Make Payment")) {
                    Text("Make Payment")
                }
                NavigationLink(destination: shellWrap(HistoryView(), title: "History")) {
                    Text("History")
                }
                NavigationLink(destination: shellWrap(ProfileView(), title: "Profile")) {
                    Text("Profile")
                }
                NavigationLink(destination: shellWrap(ComingSoonView(title: "Send Invoice"), title: "Send Invoice")) {
                    Text("Send Invoice")
                }
                NavigationLink(destination: shellWrap(ComingSoonView(title: "Pending Invoices"), title: "Pending")) {
                    Text("Pending Invoices")
                }
                NavigationLink(destination: shellWrap(ComingSoonView(title: "Link Card"), title: "Link Card")) {
                    Text("Link Card")
                }
            }
            .navigationBarTitle("Menu", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { showMenu = false })
        }
    }

    private func shellWrap<Content: View>(_ content: Content, title: String, showBack: Bool = true) -> some View {
        LoggedInShell(title: title, showBack: showBack, onMenu: { showMenu = false }, onBack: nil) {
            content
        }
        .environmentObject(session)
    }
}

// MARK: - Shell (logo + toolbar)

struct LoggedInShell<Content: View>: View {
    let title: String
    var showBack: Bool = true
    var onMenu: (() -> Void)?
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { onMenu?() }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(CzedrPalette.lightText)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Image("Czedr-auth-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                Spacer()
                if showBack {
                    Button(action: {
                        if let onBack { onBack() } else { presentationMode.wrappedValue.dismiss() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
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

            if !title.isEmpty && title != "Home" {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CzedrPalette.lightText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(CzedrPalette.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}

// MARK: - Home

struct HomeView: View {
    @Binding var showMenu: Bool
    @EnvironmentObject var session: AppSession

    var body: some View {
        LoggedInShell(title: "Home", showBack: false, onMenu: { showMenu = true }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(session.czedrId)
                        .font(.subheadline)
                        .foregroundColor(CzedrPalette.caption)
                    Text(session.buildLabel)
                        .font(.caption2)
                        .foregroundColor(CzedrPalette.caption)

                    Text("Available balance")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                    Text(session.balanceText)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(CzedrPalette.balanceGreen)

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
                            NavigationLink(destination: MakePaymentView().environmentObject(session)) {
                                tileContent("Make Payment", "dollarsign.circle")
                            }
                            NavigationLink(destination: ComingSoonView(title: "Send Invoice").environmentObject(session)) {
                                tileContent("Send Invoice", "doc.text")
                            }
                        }
                        HStack(spacing: 12) {
                            NavigationLink(destination: ComingSoonView(title: "Pending Invoices").environmentObject(session)) {
                                tileContent("Pending", "clock")
                            }
                            NavigationLink(destination: HistoryView().environmentObject(session)) {
                                tileContent("History", "list.bullet")
                            }
                        }
                    }

                    NavigationLink(destination: ProfileView().environmentObject(session)) {
                        Text("My Profile")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(CzedrPalette.charcoalButton)
                            .foregroundColor(CzedrPalette.lightText)
                            .cornerRadius(6)
                    }
                }
                .padding(16)
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

struct MakePaymentView: View {
    @EnvironmentObject var session: AppSession
    @State private var recipientId = ""
    @State private var validatedName = ""
    @State private var amount = ""
    @State private var memo = "Payment"
    @State private var pin = ""

    var body: some View {
        LoggedInShell(title: "Make Payment") {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Recipient Czedr ID", text: $recipientId)
                            .textFieldStyle(CzedrFieldStyle())
                            .autocapitalization(.allCharacters)
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
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CzedrFieldStyle())
                    TextField("Enter Description", text: $memo)
                        .textFieldStyle(CzedrFieldStyle())

                    Text("ENTER YOUR CZEDR PIN")
                        .font(.caption.bold())
                        .foregroundColor(CzedrPalette.redPrimary)
                        .padding(.top, 8)

                    SecureField("4-digit PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CzedrFieldStyle())

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
                .padding(16)
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

struct HistoryView: View {
    @EnvironmentObject var session: AppSession
    @State private var rows: [TransferRow] = []

    var body: some View {
        LoggedInShell(title: "History") {
            List(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppSession.formatMoney(cents: row.amountCents, currency: row.currency))
                        .font(.headline)
                        .foregroundColor(CzedrPalette.balanceGreen)
                    Text(row.memo).foregroundColor(CzedrPalette.lightText)
                    Text("\(row.fromCzedrId) → \(row.toCzedrId)")
                        .font(.caption)
                        .foregroundColor(CzedrPalette.caption)
                    Text(row.createdAt).font(.caption2).foregroundColor(CzedrPalette.caption)
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

struct ProfileView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        LoggedInShell(title: "Profile") {
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

struct ComingSoonView: View {
    let title: String
    var body: some View {
        LoggedInShell(title: title) {
            Text("Coming in the next SwiftUI sprint")
                .foregroundColor(CzedrPalette.caption)
                .padding()
        }
    }
}
