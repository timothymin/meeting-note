# Meeting Note

**Private, real-time meeting transcription for Apple silicon.**

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![MLX](https://img.shields.io/badge/Apple-MLX-5E5CE6)](https://github.com/ml-explore/mlx-swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/timothymin/meeting-note/actions/workflows/ci.yml/badge.svg)](https://github.com/timothymin/meeting-note/actions/workflows/ci.yml)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/timothymin)

Meeting Note is a native macOS menu-bar app that runs Whisper locally with Apple MLX, shows a near-real-time transcript, and saves each recording as a Markdown file. Audio is not sent to a transcription service.

[Download the latest release](https://github.com/timothymin/meeting-note/releases/latest) · [Report a bug](https://github.com/timothymin/meeting-note/issues/new?template=bug_report.yml) · [Request a feature](https://github.com/timothymin/meeting-note/issues/new?template=feature_request.yml)

> The current community build is ad-hoc signed. On first launch, macOS may require right-clicking the app and choosing **Open**. Apple notarization is planned for a future release.

## Features

- Native macOS menu-bar interface
- Local MLX inference on Apple silicon
- Whisper Large V3 Turbo by default
- Background model download and loading before recording starts
- Startup Whisper warm-up inference before the UI reports `Model ready`
- Live transcript updates approximately every five seconds
- Recent Markdown files directly in the menu popover
- Searchable transcript library window
- Configurable model, language, and output folder
- No account, API key, analytics, or cloud transcription

## Why Meeting Note

- **Local by default:** microphone audio and transcription stay on your Mac.
- **Ready before recording:** Whisper downloads, loads, and completes a warm-up inference before Start is enabled.
- **Markdown as the source of truth:** transcripts are ordinary portable files, not an app-only database.
- **Native and focused:** a compact SwiftUI menu-bar interface with no account, API key, or analytics.

## Requirements

- Apple silicon Mac
- macOS 14 or later
- Xcode 16 or later with command-line tools installed
- Internet access for the first build and first model download
- Several GB of free disk space for model weights and build dependencies

## Install

### Direct download

Download the DMG from [GitHub Releases](https://github.com/timothymin/meeting-note/releases/latest), open it, then drag Meeting Note onto the Applications shortcut.

### One command

Open Terminal in this folder and run:

```sh
make install
```

This builds a release app, signs it locally, installs it to `~/Applications/MeetingNote.app`, and opens it. An existing installation is preserved as a timestamped backup.

To build a distributable ZIP without installing:

```sh
make build
```

The ZIP and drag-to-Applications DMG are written to `dist/`.

You can also open `MeetingNote.xcodeproj` in Xcode and run the **MeetingNote** scheme.

## First recording

1. Click the waveform icon in the menu bar.
2. Optionally enter a meeting title.
3. Click **Start transcription**.
4. Approve microphone access.
5. The model is already ready before **Start transcription** becomes available.
6. Click **Stop and save** when finished.

The default output folder is `~/Documents/Meeting Notes`. The menu shows the six most recent files; **All transcripts** opens the full file library.

## How live transcription works

The app captures microphone audio with `AVAudioEngine`. Approximately every five seconds it sends the available audio to a resident MLX Whisper model. Consecutive chunks overlap by 1.25 seconds, and the app removes repeated words while merging results. Audio samples stay in memory and are discarded after transcription; only Markdown is persisted.

## Models

The default is `mlx-community/whisper-large-v3-turbo`, which provides the best practical multilingual speed/accuracy balance for live use. Settings also offers full Large V3, Small, and Base.

Model downloads and inference are provided by the MIT-licensed [MLX Audio Swift](https://github.com/Blaizzy/mlx-audio-swift) package. The dependency is pinned to a tested source revision for reproducible builds.

Release packaging also includes the version-matched MLX Metal shader library. The build script downloads the official MLX Swift `0.31.6` Cmlx release asset and verifies its published SHA-256 before extraction; this is required because command-line SwiftPM builds do not emit `default.metallib` automatically.

## Current limitations

- Microphone input only; macOS system audio capture is not yet included.
- Live text is chunked rather than true token-by-token streaming from an endless audio stream.
- Speaker diarization and automatic summaries are not yet included.
- The local build is ad-hoc signed, not Apple-notarized. Gatekeeper behavior can vary on other Macs.

## Privacy

Audio is processed locally and is not written to disk except for a short-lived temporary WAV used to pass each chunk into the MLX runtime. That file is deleted immediately after inference. The application contains no analytics or network transcription code. Network access is used by the model library to download model weights on first use.

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Development

```sh
make test
```

After a release build, run the real model/GPU smoke test with:

```sh
dist/MeetingNote.app/Contents/MacOS/MeetingNote --mlx-smoke-test
dist/MeetingNote.app/Contents/MacOS/MeetingNote --audio-smoke-test
```

The first command loads Whisper and transcribes generated silence to validate MLX. The second records one second from the microphone to validate the real-time CoreAudio callback and Swift concurrency boundary.

The source is also described by `Package.swift` for independent compiler checks, while the `.xcodeproj` produces the actual app bundle.

Tag-based GitHub release automation and a Homebrew cask template are included. See `RELEASING.md`.

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT. MLX Audio Swift, MLX, and downloaded model weights retain their own license terms.
