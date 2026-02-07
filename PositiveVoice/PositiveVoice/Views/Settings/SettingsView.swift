import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section("アカウント") {
                    NavigationLink(destination: ProfileEditView()) {
                        SettingsRow(icon: "person.fill", title: "プロフィール編集", color: AppColors.accent)
                    }

                    NavigationLink(destination: Text("メールアドレス変更")) {
                        SettingsRow(icon: "envelope.fill", title: "メールアドレス変更", color: AppColors.primary)
                    }

                    NavigationLink(destination: Text("パスワード変更")) {
                        SettingsRow(icon: "lock.fill", title: "パスワード変更", color: AppColors.secondary)
                    }
                }

                // App settings section
                Section("アプリ設定") {
                    NavigationLink(destination: Text("通知設定")) {
                        SettingsRow(icon: "bell.fill", title: "通知設定", color: AppColors.error)
                    }

                    // v2: Theme picker
                    NavigationLink(destination: ThemeSettingView()) {
                        HStack {
                            SettingsRow(icon: "moon.fill", title: "テーマ", color: .purple)
                            Spacer()
                            Text(appState.themeSetting.displayName)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }

                // Support section
                Section("サポート") {
                    NavigationLink(destination: Text("利用規約")) {
                        SettingsRow(icon: "doc.text.fill", title: "利用規約", color: .gray)
                    }

                    NavigationLink(destination: Text("プライバシーポリシー")) {
                        SettingsRow(icon: "hand.raised.fill", title: "プライバシーポリシー", color: .teal)
                    }

                    NavigationLink(destination: Text("お問い合わせ")) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "お問い合わせ", color: .indigo)
                    }
                }

                // Logout section
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("ログアウト")
                                .font(AppFonts.body())
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }

                // Delete account section
                Section {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("アカウント削除")
                                .font(AppFonts.body())
                                .foregroundColor(.red.opacity(0.7))
                            Spacer()
                        }
                    }
                }

                // Version
                Section {
                    HStack {
                        Spacer()
                        Text("Version 1.0.0")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .alert("ログアウト", isPresented: $showLogoutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("本当にログアウトしますか？")
            }
            .alert("アカウント削除", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    // TODO: Delete account
                }
            } message: {
                Text("アカウントを削除すると、すべてのデータが失われます。本当に削除しますか？")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)

            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nickname: String = ""
    @State private var bio: String = ""

    var body: some View {
        Form {
            Section("ニックネーム") {
                TextField("ニックネーム", text: $nickname)
            }

            Section("自己紹介") {
                TextEditor(text: $bio)
                    .frame(height: 100)
            }

            Section {
                Button("保存") {
                    // TODO: Save profile
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(AppColors.primary)
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nickname = authViewModel.currentUser?.nickname ?? ""
            bio = authViewModel.currentUser?.bio ?? ""
        }
    }
}

// v2: テーマ設定画面
struct ThemeSettingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            ForEach(ThemeSetting.allCases, id: \.self) { setting in
                Button(action: {
                    appState.setTheme(setting)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(setting.displayName)
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textPrimary)

                            Text(themeDescription(setting))
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if appState.themeSetting == setting {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("テーマ設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeDescription(_ setting: ThemeSetting) -> String {
        switch setting {
        case .system: return "端末の設定に合わせて自動で切り替わります"
        case .light: return "常に明るい背景で表示します"
        case .dark: return "常に暗い背景で表示します"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
