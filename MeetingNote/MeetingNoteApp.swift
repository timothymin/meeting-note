import Darwin
import Foundation
import SwiftUI

@main
struct MeetingNoteApp: App {
    @StateObject private var appModel: AppModel

    init() {
        let isAudioSmokeTest = CommandLine.arguments.contains("--audio-smoke-test")
        let model = AppModel(prepareModelOnLaunch: !isAudioSmokeTest)
        _appModel = StateObject(wrappedValue: model)

        if CommandLine.arguments.contains("--mlx-smoke-test") {
            Task { @MainActor in
                do {
                    try await model.runMLXSmokeTest()
                    print("MLX smoke test passed")
                    Darwin.exit(EXIT_SUCCESS)
                } catch {
                    FileHandle.standardError.write(Data("MLX smoke test failed: \(error)\n".utf8))
                    Darwin.exit(EXIT_FAILURE)
                }
            }
        } else if CommandLine.arguments.contains("--audio-smoke-test") {
            Task { @MainActor in
                do {
                    try await model.runAudioCaptureSmokeTest()
                    print("Audio capture smoke test passed")
                    Darwin.exit(EXIT_SUCCESS)
                } catch {
                    FileHandle.standardError.write(Data("Audio capture smoke test failed: \(error)\n".utf8))
                    Darwin.exit(EXIT_FAILURE)
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appModel)
        } label: {
            Label("Local Transcribe", systemImage: appModel.isRecording ? "waveform.circle.fill" : "waveform.circle")
        }
        .menuBarExtraStyle(.window)

        Window("Local Transcribe", id: "transcript") {
            TranscriptWindow()
                .environmentObject(appModel)
        }
        .defaultSize(width: 720, height: 560)

        Settings {
            SettingsView()
                .environmentObject(appModel)
                .frame(width: 520)
        }
    }
}
