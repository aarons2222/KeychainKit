//
//  ContentView.swift
//  KeychainKit Demo
//
//  Created by Aaron Strickland on 11/02/2026.
//

import SwiftUI
import KeychainKit

// MARK: - Demo Model

nonisolated struct UserCredentials: Codable, Sendable {
    var username: String
    var email: String
    var tier: String
}

// MARK: - Main View

struct ContentView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StringDemoView()
                .tabItem {
                    Label("Strings", systemImage: "textformat")
                }
                .tag(0)
            
            CodableDemoView()
                .tabItem {
                    Label("Codable", systemImage: "doc.text")
                }
                .tag(1)
            
            PropertyWrapperDemoView()
                .tabItem {
                    Label("@Keychain", systemImage: "at")
                }
                .tag(2)
            
            BiometricDemoView()
                .tabItem {
                    Label("Biometric", systemImage: "faceid")
                }
                .tag(3)
            
            KeysBrowserView()
                .tabItem {
                    Label("Browse", systemImage: "key.fill")
                }
                .tag(4)
        }
    }
}

// MARK: - String Demo

struct StringDemoView: View {
    
    private let keychain = Keychain(service: "com.keychainkit.demo")
    
    @State private var key = "api-token"
    @State private var value = ""
    @State private var retrieved = ""
    @State private var status = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Store a String") {
                    TextField("Key", text: $key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Value", text: $value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Button("Save to Keychain") {
                        save()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
                
                Section("Retrieve") {
                    Button("Load from Keychain") {
                        load()
                    }
                    .disabled(key.isEmpty)
                    
                    if !retrieved.isEmpty {
                        HStack {
                            Text("Value:")
                                .foregroundStyle(.secondary)
                            Text(retrieved)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Delete Key", role: .destructive) {
                        delete()
                    }
                    .disabled(key.isEmpty)
                    
                    Button("Check if Exists") {
                        checkExists()
                    }
                    .disabled(key.isEmpty)
                }
                
                if !status.isEmpty {
                    Section("Status") {
                        Text(status)
                            .foregroundStyle(status.contains("✅") ? .green : status.contains("❌") ? .red : .orange)
                            .fontDesign(.monospaced)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("String Storage")
            .scrollDismissesKeyboard(.interactively)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
        }
    }
    
    private func save() {
        do {
            try keychain.set(value, forKey: key)
            status = "✅ Saved \"\(key)\" to keychain"
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
    
    private func load() {
        do {
            if let result = try keychain.getString(forKey: key) {
                retrieved = result
                status = "✅ Retrieved \"\(key)\""
            } else {
                retrieved = ""
                status = "⚠️ No value found for \"\(key)\""
            }
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
    
    private func delete() {
        do {
            try keychain.remove(forKey: key)
            retrieved = ""
            status = "✅ Deleted \"\(key)\""
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
    
    private func checkExists() {
        do {
            let exists = try keychain.contains(key: key)
            status = exists ? "✅ Key \"\(key)\" exists" : "⚠️ Key \"\(key)\" not found"
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
}

// MARK: - Codable Demo

struct CodableDemoView: View {
    
    private let keychain = Keychain(service: "com.keychainkit.demo")
    private let storageKey = "user-credentials"
    
    @State private var username = "aaron"
    @State private var email = "aaron@example.com"
    @State private var tier = "Pro"
    @State private var loadedUser: UserCredentials?
    @State private var status = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Credentials") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    Picker("Tier", selection: $tier) {
                        Text("Free").tag("Free")
                        Text("Pro").tag("Pro")
                        Text("Enterprise").tag("Enterprise")
                    }
                }
                
                Section {
                    Button("Save Credentials") {
                        saveUser()
                    }
                    
                    Button("Load Credentials") {
                        loadUser()
                    }
                }
                
                if let user = loadedUser {
                    Section("Loaded from Keychain") {
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Tier", value: user.tier)
                    }
                }
                
                if !status.isEmpty {
                    Section("Status") {
                        Text(status)
                            .foregroundStyle(status.contains("✅") ? .green : .red)
                            .fontDesign(.monospaced)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Codable Storage")
            .scrollDismissesKeyboard(.interactively)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
        }
    }
    
    private func saveUser() {
        let creds = UserCredentials(username: username, email: email, tier: tier)
        do {
            try keychain.set(creds, forKey: storageKey)
            status = "✅ Saved UserCredentials as JSON"
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
    
    private func loadUser() {
        do {
            loadedUser = try keychain.get(UserCredentials.self, forKey: storageKey)
            status = loadedUser != nil ? "✅ Loaded UserCredentials" : "⚠️ No credentials stored"
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
}

// MARK: - Property Wrapper Demo

struct PropertyWrapperDemoView: View {
    
    @KeychainValue(key: "demo-token", keychain: Keychain(service: "com.keychainkit.demo"), defaultValue: "")
    var token: String
    
    @KeychainValue(key: "demo-counter", keychain: Keychain(service: "com.keychainkit.demo"), defaultValue: 0)
    var counter: Int
    
    @KeychainValue(key: "demo-premium", keychain: Keychain(service: "com.keychainkit.demo"), defaultValue: false)
    var isPremium: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("@KeychainValue — Auto-Synced")) {
                    Text("These values persist in the keychain automatically. Kill the app and reopen — they'll still be here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("API Token") {
                    TextField("Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fontDesign(.monospaced)
                    
                    Text("Stored: \(token.isEmpty ? "(empty)" : token)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Counter") {
                    HStack {
                        Text("\(counter)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                        
                        Spacer()
                        
                        Button {
                            let newVal = counter - 1
                            counter = newVal
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                        }
                        
                        Button {
                            let newVal = counter + 1
                            counter = newVal
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                }
                
                Section("Premium Toggle") {
                    Toggle("Premium User", isOn: $isPremium)
                    
                    Text(isPremium ? "🌟 Premium active" : "Free tier")
                        .foregroundStyle(isPremium ? .yellow : .secondary)
                }
                
                Section {
                    Button("Reset All", role: .destructive) {
                        token = ""
                        counter = 0
                        isPremium = false
                    }
                }
            }
            .navigationTitle("@KeychainValue")
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Biometric Demo

struct BiometricDemoView: View {
    
    private let keychain = Keychain(service: "com.keychainkit.demo")
    private let secretKey = "biometric-secret"
    
    @State private var secretInput = ""
    @State private var revealedSecret = ""
    @State private var status = ""
    @State private var biometricAvailable = false
    @State private var biometricType = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Device Info") {
                    LabeledContent("Biometric Available", value: biometricAvailable ? "Yes" : "No")
                    if !biometricType.isEmpty {
                        LabeledContent("Type", value: biometricType)
                    }
                }
                
                Section("Store Secret (Biometric Protected)") {
                    SecureField("Enter a secret", text: $secretInput)
                    
                    Button("Save with Biometric Lock") {
                        saveSecret()
                    }
                    .disabled(secretInput.isEmpty || !biometricAvailable)
                }
                
                Section("Retrieve Secret") {
                    Button("Unlock with \(biometricType.isEmpty ? "Biometrics" : biometricType)") {
                        Task { await loadSecret() }
                    }
                    .disabled(!biometricAvailable)
                    
                    if !revealedSecret.isEmpty {
                        HStack {
                            Text("Secret:")
                                .foregroundStyle(.secondary)
                            Text(revealedSecret)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                        }
                    }
                }
                
                if !biometricAvailable {
                    Section {
                        Label("Biometrics not available on this device. Try on a real device with Face ID or Touch ID.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                if !status.isEmpty {
                    Section("Status") {
                        Text(status)
                            .foregroundStyle(status.contains("✅") ? .green : status.contains("❌") ? .red : .orange)
                            .fontDesign(.monospaced)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Biometric Lock")
            .scrollDismissesKeyboard(.interactively)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
            .onAppear {
                biometricAvailable = Keychain.isBiometricAuthenticationAvailable()
                biometricType = Keychain.biometricType() ?? ""
            }
        }
    }
    
    private func saveSecret() {
        do {
            try keychain.setWithBiometric(secretInput, forKey: secretKey, prompt: "Authenticate to save secret")
            status = "✅ Secret saved with biometric protection"
            secretInput = ""
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
    
    private func loadSecret() async {
        do {
            if let secret = try await keychain.getStringWithBiometric(forKey: secretKey, prompt: "Authenticate to reveal secret") {
                revealedSecret = secret
                status = "✅ Secret unlocked"
            } else {
                status = "⚠️ No secret stored"
            }
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
}

// MARK: - Keys Browser

struct KeysBrowserView: View {
    
    private let keychain = Keychain(service: "com.keychainkit.demo")
    
    @State private var allKeys: [String] = []
    @State private var status = ""
    
    var body: some View {
        NavigationStack {
            List {
                if allKeys.isEmpty {
                    ContentUnavailableView(
                        "No Keys",
                        systemImage: "key.slash",
                        description: Text("Store some values in the other tabs first")
                    )
                } else {
                    ForEach(allKeys, id: \.self) { key in
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.yellow)
                            Text(key)
                                .fontDesign(.monospaced)
                        }
                    }
                    .onDelete(perform: deleteKeys)
                }
            }
            .navigationTitle("All Keys")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Refresh") { refresh() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete All", role: .destructive) { deleteAll() }
                        .disabled(allKeys.isEmpty)
                }
            }
            .onAppear { refresh() }
            
            if !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private func refresh() {
        do {
            allKeys = try keychain.keys().sorted()
            status = "\(allKeys.count) key\(allKeys.count == 1 ? "" : "s") stored"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    private func deleteKeys(at offsets: IndexSet) {
        for index in offsets {
            let key = allKeys[index]
            try? keychain.remove(forKey: key)
        }
        refresh()
    }
    
    private func deleteAll() {
        try? keychain.removeAll()
        refresh()
    }
}

#Preview {
    ContentView()
}
