
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case light, dark, system
}

enum AppLanguage: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case english = "en"
    case slovak = "sk"
    case system = "system"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .slovak: return "Slovenčina"
        case .system: return "System"
        }
    }
}

struct AccountView: View {
    @ObservedObject var VM = AccountViewModel()
    @ObservedObject private var aiService = AIVisionService.shared
    @EnvironmentObject var session: UserSession
    @AppStorage("theme") private var theme: AppTheme = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system

    @State private var showAPIKeySheet = false
    @State private var apiKeyInput = ""
    @State private var apiKeyNoteInput = ""
    @State private var isValidatingAPIKey = false
    @State private var apiKeyValidationFailed: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let user = session.mainUser {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.fiitPrimary.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)).uppercased())
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.fiitPrimary)
                        }

                        VStack(spacing: 4) {
                            Text("\(user.firstName) \(user.lastName)")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.forText)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 0) {
                    NavigationLink {
                        AccountPersonalInformationView(VM: VM)
                            .environmentObject(session)
                            .navigationBarBackButtonHidden(VM.isEditing)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.text.rectangle")
                                .font(.subheadline)
                                .foregroundStyle(.fiitPrimary)
                                .frame(width: 20)
                            Text("personalInfoTitle")
                                .font(.subheadline)
                                .foregroundStyle(.forText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    Divider().padding(.leading, 44)

                    NavigationLink {
                        AccountChangePasswordView(VM: VM)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "key.fill")
                                .font(.subheadline)
                                .foregroundStyle(.fiitPrimary)
                                .frame(width: 20)
                            Text("changePasswordButton")
                                .font(.subheadline)
                                .foregroundStyle(.forText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("rolesTitle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    NavigationLink {
                        AccountMyRolesView(VM: VM)
                            .environmentObject(session)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.badge.shield.checkmark")
                                .font(.subheadline)
                                .foregroundStyle(.fiitPrimary)
                                .frame(width: 20)
                            Text("myRolesAndPermissionsTitle")
                                .font(.subheadline)
                                .foregroundStyle(.forText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    if let mainUser = session.mainUser {
                        if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                            Divider().padding(.leading, 44)

                            NavigationLink {
                                AccountManageRolesView(VM: VM)
                                    .environmentObject(session)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "gearshape.2.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.fiitPrimary)
                                        .frame(width: 20)
                                    Text("manageRolesTitle")
                                        .font(.subheadline)
                                        .foregroundStyle(.forText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("preferencesSection")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    if let mainUser = session.mainUser,
                       mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                        mainUser.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_ITEM" }) {

                        Toggle(isOn: Binding(
                            get: { AIVisionService.shared.hasAPIKey && VM.useAI },
                            set: { VM.useAI = $0 }
                        )) {
                            HStack(spacing: 14) {
                                Image(systemName: "eye.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(AIVisionService.shared.hasAPIKey ? .fiitPrimary : .gray)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("useAiForImageRecognitionToggle")
                                        .font(.subheadline)
                                        .foregroundStyle(AIVisionService.shared.hasAPIKey ? .forText : .secondary)
                                    if !AIVisionService.shared.hasAPIKey {
                                        Text("aiNeedsApiKeyHint")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .tint(.fiitPrimary)
                        .disabled(!AIVisionService.shared.hasAPIKey)

                        Divider().padding(.leading, 44)

                        Toggle(isOn: $VM.useWizard) {
                            HStack(spacing: 14) {
                                Image(systemName: "wand.and.stars")
                                    .font(.subheadline)
                                    .foregroundStyle(.fiitPrimary)
                                    .frame(width: 20)
                                Text("useWizardForItemCreationToggle")
                                    .font(.subheadline)
                                    .foregroundStyle(.forText)
                            }
                        }
                        .tint(.fiitPrimary)

                        Divider().padding(.leading, 44)
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "paintbrush.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                            .frame(width: 20)

                        Picker("themeLabel", selection: $theme) {
                            Text("lightTheme").tag(AppTheme.light)
                            Text("darkTheme").tag(AppTheme.dark)
                            Text("systemTheme").tag(AppTheme.system)
                        }
                        .tint(.fiitPrimary)
                    }

                    Divider().padding(.leading, 44)

                    HStack(spacing: 14) {
                        Image(systemName: "globe")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                            .frame(width: 20)

                        Picker("languageLabel", selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .tint(.fiitPrimary)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                if let mainUser = session.mainUser,
                   mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                    apiKeySection
                }

                Button {
                    session.mainUser = nil
                    VM.logout()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline)
                        Text("logOutButton")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("accountTitle")
        .sheet(isPresented: $showAPIKeySheet) {
            NavigationStack {
                apiKeyForm
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }


    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "key.horizontal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("geminiApiKeyTitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            let ai = aiService

            if ai.hasAPIKey {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("apiKeyIsSetLabel")
                            .font(.subheadline)
                            .foregroundStyle(.forText)
                        if ai.isUsingKeychain {
                            let note = ai.apiKeyNote
                            Group {
                                if note.isEmpty {
                                    Text("apiKeyStoredInKeychainLabel")
                                } else {
                                    Text(verbatim: note)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else {
                            Text("usingDefaultKeyLabel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                Divider().padding(.leading, 44)

                HStack(spacing: 12) {
                    Button {
                        apiKeyInput = ""
                        apiKeyNoteInput = ai.apiKeyNote
                        apiKeyValidationFailed = false
                        isValidatingAPIKey = false
                        showAPIKeySheet = true
                    } label: {
                        Text("changeButton")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.fiitPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.fiitPrimary)
                    }

                    if ai.isUsingKeychain {
                        Button {
                            ai.deleteAPIKey()
                        } label: {
                            Text("removeButton")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text("noApiKeyConfiguredLabel")
                        .font(.subheadline)
                        .foregroundStyle(.forText)
                    Spacer()
                }

                Button {
                    apiKeyInput = ""
                    apiKeyNoteInput = ""
                    apiKeyValidationFailed = false
                    isValidatingAPIKey = false
                    showAPIKeySheet = true
                } label: {
                    Text("addApiKeyButton")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.fiitPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.fiitPrimary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var apiKeyForm: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("apiKeyLabel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("pasteApiKeyPlaceholder", text: $apiKeyInput)
                    .textContentType(.password)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    .onChange(of: apiKeyInput) { _, _ in
                        apiKeyValidationFailed = false
                    }

                if apiKeyValidationFailed {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text("apiKeyValidationFailedHint")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("noteLabel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("apiKeyOwnerPlaceholder", text: $apiKeyNoteInput)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            Text("apiKeySecurityNote")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(20)
        .navigationTitle("geminiApiKeyTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") { showAPIKeySheet = false }
                    .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                if isValidatingAPIKey {
                    ProgressView()
                } else {
                    Button("saveButton") {
                        let key = apiKeyInput
                        let note = apiKeyNoteInput
                        Task {
                            isValidatingAPIKey = true
                            apiKeyValidationFailed = false
                            do {
                                try await AIVisionService.shared.validateAPIKey(key)
                                AIVisionService.shared.saveAPIKey(key, note: note)
                                isValidatingAPIKey = false
                                showAPIKeySheet = false
                            } catch {
                                print("api key validation failed: \(error.localizedDescription)")
                                apiKeyValidationFailed = true
                                isValidatingAPIKey = false
                            }
                        }
                    }
                    .foregroundStyle(apiKeyInput.isEmpty ? .gray : .fiitPrimary)
                    .disabled(apiKeyInput.isEmpty)
                }
            }
        }
    }
}
