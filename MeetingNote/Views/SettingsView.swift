import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Configure local transcription and Markdown storage.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                settingsSection(
                    title: "Transcription",
                    subtitle: "Models run entirely on this Mac.",
                    icon: "waveform.badge.mic"
                ) {
                    settingRow("Whisper model", help: "The selected model is downloaded and loaded immediately.") {
                        Picker("", selection: $appModel.selectedModel) {
                            ForEach(appModel.availableModels, id: \.self) { model in
                                Text(model.components(separatedBy: "/").last ?? model).tag(model)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                        .disabled(appModel.isRecording || appModel.isBusy)
                    }
                    Divider()
                    settingRow("Language", help: "The selected dominant language stays fixed for the entire recording.") {
                        Picker("", selection: $appModel.language) {
                            ForEach(appModel.availableLanguages) { language in
                                Text("\(language.label) — \(language.detail)")
                                    .tag(language.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                        .disabled(appModel.isRecording || appModel.isBusy)
                    }
                }

                settingsSection(
                    title: "Files",
                    subtitle: "Markdown remains the source of truth.",
                    icon: "folder.fill"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(appModel.outputFolder.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(AppDesign.mutedBackground))
                        HStack {
                            Button("Choose Folder…") { appModel.chooseOutputFolder() }
                            Button("Show in Finder") { appModel.revealOutputFolder() }
                        }
                    }
                }

                settingsSection(
                    title: "Privacy",
                    subtitle: "No account, analytics, or cloud transcription.",
                    icon: "lock.shield.fill"
                ) {
                    Label {
                        Text("Microphone audio is processed locally. Temporary chunks are deleted immediately after MLX inference.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
            }
            .padding(28)
        }
        .frame(width: 600, height: 560)
        .background(VibrancyBackground())
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.12)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 10.5)).foregroundStyle(.secondary)
                }
            }
            AppCard { content() }
        }
    }

    private func settingRow<Control: View>(_ title: String, help: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(help).font(.system(size: 10.5)).foregroundStyle(.secondary)
            }
            Spacer()
            control()
        }
    }
}
