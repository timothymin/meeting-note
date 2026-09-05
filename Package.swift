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
            url: "https://github.com/timothymin/mlx-audio-swift.git",
            revision: "243679e4d4334edde0903952e59d4b30b38721e1"
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
