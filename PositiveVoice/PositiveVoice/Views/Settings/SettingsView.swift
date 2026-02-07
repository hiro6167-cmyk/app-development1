import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isDarkMode = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section("アカウント") {
                    NavigationLink(destination: ProfileEditView()) {
                        SettingsRow(icon: "person.fill", title: "プロフィール編集", color: .blue)
                    }

                    NavigationLink(destination: Text("メールアドレス変更")) {
                        SettingsRow(icon: "envelope.fill", title: "メールアドレス変更", color: AppColors.primary)
                    }

                    NavigationLink(destination: Text("パスワード変更")) {
                        SettingsRow(icon: "lock.fill", title: "パスワード変更", color: .orange)
                    }
                }

                // App settings section
                Section("アプリ設定") {
                    NavigationLink(destination: Text("通知設定")) {
                        SettingsRow(icon: "bell.fill", title: "通知設定", color: .red)
                    }

                    HStack {
                        SettingsRow(icon: "moon.fill", title: "ダークモード", color: .purple)
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
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

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
