# Security Policy

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could expose user audio, transcripts, local files, or system access.

Use GitHub's private vulnerability reporting feature for this repository. Include the affected version, reproduction steps, impact, and any suggested mitigation. You should receive an acknowledgement within seven days.

## Security model

Local Transcribe performs transcription locally. It uses network access only to download model and build dependencies from their upstream hosts. The app has no account system, analytics, remote transcription endpoint, or background upload feature.
