#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
INSTALL_DIR="${LOCAL_TRANSCRIBE_INSTALL_DIR:-${HOME}/Applications}"
SOURCE_APP="${PROJECT_ROOT}/dist/Local Transcribe.app"
DESTINATION="${INSTALL_DIR}/Local Transcribe.app"
LEGACY_APP="${INSTALL_DIR}/MeetingNote.app"

"${SCRIPT_DIR}/build-release.sh"
mkdir -p "${INSTALL_DIR}"

if [[ -e "${LEGACY_APP}" ]]; then
  LEGACY_BACKUP="${INSTALL_DIR}/MeetingNote.pre-local-transcribe.$(date +%Y%m%d-%H%M%S).app"
  mv "${LEGACY_APP}" "${LEGACY_BACKUP}"
  print "Previous Meeting Note app preserved at ${LEGACY_BACKUP}"
fi

if [[ -e "${DESTINATION}" ]]; then
  BACKUP="${INSTALL_DIR}/Local Transcribe.backup.$(date +%Y%m%d-%H%M%S).app"
  mv "${DESTINATION}" "${BACKUP}"
  print "Previous app preserved at ${BACKUP}"
fi

ditto "${SOURCE_APP}" "${DESTINATION}"
open "${DESTINATION}"
print "Installed ${DESTINATION}"
