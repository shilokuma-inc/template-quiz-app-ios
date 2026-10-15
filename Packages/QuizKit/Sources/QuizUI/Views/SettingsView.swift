import QuizCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: QuizAppModel
    @State private var isConfirmingReset = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("出題") {
                    Picker("1 回の出題数", selection: $model.settings.questionCount) {
                        ForEach(model.configuration.questionCountOptions, id: \.self) { count in
                            Text("\(count) 問").tag(Int?.some(count))
                        }
                        Text("すべて").tag(Int?.none)
                    }
                    .accessibilityIdentifier("questionCountPicker")
                    Toggle("選択肢をシャッフル", isOn: $model.settings.shufflesChoices)
                }

                Section("操作") {
                    Toggle("振動フィードバック", isOn: $model.settings.hapticsEnabled)
                }

                Section {
                    Button("学習記録をリセット", role: .destructive) {
                        isConfirmingReset = true
                    }
                    .accessibilityIdentifier("resetProgressButton")
                } header: {
                    Text("学習記録")
                } footer: {
                    Text("正解・不正解の記録と挑戦回数を削除します。設定は削除されません。")
                }

                if model.configuration.ads.provider.showsPrivacyOptions {
                    Section("広告") {
                        Button("広告のプライバシー設定") {
                            Task { await model.configuration.ads.provider.presentPrivacyOptions() }
                        }
                    }
                }

                Section("このアプリについて") {
                    let links = model.configuration.links
                    if let url = links.privacyPolicy {
                        Link("プライバシーポリシー", destination: url)
                    }
                    if let url = links.termsOfUse {
                        Link("利用規約", destination: url)
                    }
                    if let url = links.support {
                        Link("お問い合わせ", destination: url)
                    }
                    LabeledContent("バージョン", value: Bundle.main.quizVersionText)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .accessibilityIdentifier("closeSettingsButton")
                }
            }
            .confirmationDialog("学習記録をリセットしますか？", isPresented: $isConfirmingReset, titleVisibility: .visible) {
                Button("リセットする", role: .destructive) {
                    model.resetProgress()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません")
            }
        }
    }
}

#Preview {
    SettingsView(model: .preview)
}
