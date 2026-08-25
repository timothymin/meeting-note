// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MeetingNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MeetingNote", targets: ["MeetingNote"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Blaizzy/mlx-audio-swift.git",
            revision: "cae704f53bc32a3d0b606823828fbc5bedaaf388"
        )
    ],
    targets: [
        .executableTarget(
            name: "MeetingNote",
            dependencies: [
                .product(name: "MLXAudioCore", package: "mlx-audio-swift"),
                .product(name: "MLXAudioSTT", package: "mlx-audio-swift")
            ],
            path: "MeetingNote",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "MeetingNoteTests",
            dependencies: ["MeetingNote"],
            path: "MeetingNoteTests"
        )
    ]
)
