import SwiftUI

struct TranscriptWindow: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationSplitView {
            List(appModel.recentFiles, selection: selectedURL) { file in
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.title).lineLimit(1)
                    Text(file.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                }
                .tag(file.url)
                .contextMenu {
                    Button("Reveal in Finder") { appModel.reveal(file) }
                    Button("Move to Trash", role: .destructive) { appModel.deleteTranscript(file) }
                }
            }
            .navigationTitle("Transcripts")
            .toolbar {
                Button(action: appModel.refreshLibrary) { Image(systemName: "arrow.clockwise") }
            }
        } detail: {
            VStack(spacing: 0) {
                header
                Divider()
                ScrollView {
                    Text(detailText)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(detailText.isEmpty ? .tertiary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(24)
                }
            }
        }
        .onAppear { appModel.refreshLibrary() }
    }

    private var selectedURL: Binding<URL?> {
        Binding(
            get: { appModel.selectedTranscript?.url },
            set: { url in appModel.selectedTranscript = appModel.recentFiles.first { $0.url == url } }
        )
    }

    private var detailText: String {
        if appModel.isRecording || !appModel.displayText.isEmpty { return appModel.displayText }
        return appModel.selectedTranscript?.content ?? "Select a transcript or start a new recording."
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(detailTitle).font(.title2.weight(.semibold))
                Text(appModel.isRecording ? appModel.status : appModel.selectedTranscript?.url.lastPathComponent ?? appModel.status)
                    .foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Button("Copy", systemImage: "doc.on.doc") { appModel.copyTranscript() }
            if let file = appModel.selectedTranscript, !appModel.isRecording {
                Button("Show file", systemImage: "folder") { appModel.reveal(file) }
            }
            Button(action: appModel.toggleRecording) {
                Label(appModel.isRecording ? "Stop" : "Record", systemImage: appModel.isRecording ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(appModel.isRecording ? .red : .accentColor)
            .disabled(appModel.isBusy)
        }
        .padding()
    }

    private var detailTitle: String {
        if appModel.isRecording || !appModel.displayText.isEmpty {
            return appModel.title.isEmpty ? "Untitled meeting" : appModel.title
        }
        return appModel.selectedTranscript?.title ?? "Local Transcribe"
    }
}
