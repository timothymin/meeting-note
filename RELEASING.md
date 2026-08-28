# Releasing Local Transcribe

## Local package

Run `make build`. This creates both a ZIP and a drag-to-Applications DMG in `dist/`.

## GitHub release

1. Push this project to GitHub.
2. Push a version tag such as `v0.1.0`.
3. The release workflow builds, tests, and attaches the ZIP and DMG automatically.

## Homebrew cask

Copy `Packaging/local-transcribe.rb.template` into a Homebrew tap repository as `local-transcribe.rb`, then replace:

- `OWNER/REPOSITORY` with the public GitHub repository
- `VERSION` with the release version without `v`
- `SHA256` with `shasum -a 256 dist/LocalTranscribe-macOS-arm64.zip`

Users can then install with `brew install --cask OWNER/TAP/local-transcribe`.

## Apple signing and notarization

Local packages are ad-hoc signed. Public releases should use a Developer ID Application certificate and Apple notarization so downloaded builds open without a Gatekeeper warning. Store the signing certificate and notarization credentials as GitHub Actions secrets; never commit them.
