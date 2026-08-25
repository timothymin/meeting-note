import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 12) {
                if appModel.isRecording || appModel.isBusy || !appModel.displayText.isEmpty {
                    liveCard
                } else {
                    readyCard
                    recentSection
                }

                if let error = appModel.errorMessage {
                    errorBanner(error)
                }
                footer
            }
            .padding(12)
        }
        .frame(width: AppDesign.popoverWidth)
        .background(VibrancyBackground())
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.97, anchor: .top)
        .onAppear {
            appModel.refreshLibrary()
            appeared = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) { appeared = true }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("Meeting Note")
                    .font(.system(size: 14, weight: .bold))
                HStack(spacing: 5) {
                    Circle()
                        .fill(headerStatusColor)
                        .frame(width: 6, height: 6)
                    Text(appModel.status)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if appModel.isBusy || appModel.isPreparingModel { ProgressView().controlSize(.small) }
            Button { openSettings() } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var readyCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New transcript")
                            .font(.system(size: 15, weight: .bold))
                        Text("Whisper Large V3 Turbo · On device")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusPill(text: modelPillText, color: modelStatusColor)
                }

                TextField("Meeting title (optional)", text: $appModel.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(AppDesign.mutedBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(AppDesign.cardBorder, lineWidth: 1)
                    )

                primaryButton
            }
        }
    }

    private var liveCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(appModel.title.isEmpty ? "Live transcript" : appModel.title)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        Text(appModel.selectedModel.components(separatedBy: "/").last ?? appModel.selectedModel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusPill(text: appModel.isRecording ? "Recording" : "Ready", color: appModel.isRecording ? .red : .green)
                }

                ScrollView {
                    Text(appModel.displayText.isEmpty ? "Listening for speech…" : appModel.displayText)
                        .font(.system(size: 11.5))
                        .lineSpacing(3)
                        .foregroundStyle(appModel.displayText.isEmpty ? .tertiary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(height: 142)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.1)))

                primaryButton
            }
        }
    }

    private var primaryButton: some View {
        Button(action: primaryButtonAction) {
            Label(
                primaryButtonTitle,
                systemImage: primaryButtonIcon
            )
            .font(.system(size: 12, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
        }
        .buttonStyle(.borderedProminent)
        .tint(appModel.isRecording ? .red : .accentColor)
        .disabled(appModel.isBusy || appModel.isPreparingModel)
    }

    private func primaryButtonAction() {
        if appModel.modelPreparationState == .failed {
            Task { await appModel.prepareModel() }
        } else {
            appModel.toggleRecording()
        }
    }

    private var primaryButtonTitle: String {
        if appModel.isRecording { return "Stop & Save" }
        switch appModel.modelPreparationState {
        case .preparing: return "Preparing Whisper…"
        case .ready: return "Start Transcription"
        case .failed: return "Retry Model Loading"
        }
    }

    private var primaryButtonIcon: String {
        if appModel.isRecording { return "stop.fill" }
        switch appModel.modelPreparationState {
        case .preparing: return "arrow.down.circle"
        case .ready: return "mic.fill"
        case .failed: return "arrow.clockwise"
        }
    }

    private var modelPillText: String {
        switch appModel.modelPreparationState {
        case .preparing: return "Loading"
        case .ready: return "Ready"
        case .failed: return "Error"
        }
    }

    private var modelStatusColor: Color {
        switch appModel.modelPreparationState {
        case .preparing: return .orange
        case .ready: return .green
        case .failed: return .red
        }
    }

    private var headerStatusColor: Color {
        if appModel.isRecording { return .red }
        return modelStatusColor
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent transcripts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !appModel.recentFiles.isEmpty {
                    Button("View all") { openWindow(id: "transcript") }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 2)

            if appModel.recentFiles.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No transcripts yet").font(.system(size: 11, weight: .semibold))
                        Text("Finished meetings appear here as Markdown.")
                            .font(.system(size: 9.5)).foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppDesign.cardBackground))
            } else {
                VStack(spacing: 6) {
                    ForEach(appModel.recentFiles.prefix(4)) { file in
                        TranscriptFileRow(file: file) {
                            appModel.selectTranscript(file)
                            openWindow(id: "transcript")
                        }
                        .contextMenu {
                            Button("Open") {
                                appModel.selectTranscript(file)
                                openWindow(id: "transcript")
                            }
                            Button("Reveal in Finder") { appModel.reveal(file) }
                            Divider()
                            Button("Move to Trash", role: .destructive) { appModel.deleteTranscript(file) }
                        }
                    }
                }
            }
        }
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error).lineLimit(3)
            Spacer(minLength: 0)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.orange)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.1)))
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button { openWindow(id: "transcript") } label: { Label("Library", systemImage: "books.vertical") }
            Button { appModel.revealOutputFolder() } label: { Label("Files", systemImage: "folder") }
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: { Image(systemName: "power") }
                .help("Quit Meeting Note")
        }
        .buttonStyle(.plain)
        .font(.system(size: 10.5, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 2)
    }
}

private struct TranscriptFileRow: View {
    let file: TranscriptFile
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.12))
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 11)).foregroundStyle(Color.accentColor)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.title).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                    HStack(spacing: 5) {
                        Text(file.createdAt, style: .relative)
                        if let duration = file.duration {
                            Text("·")
                            Text(duration.formattedDuration)
                        }
                    }
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovered ? Color.primary.opacity(0.075) : AppDesign.cardBackground)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppDesign.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        let minutes = max(1, Int(self) / 60)
        return "\(minutes)m"
    }
}
