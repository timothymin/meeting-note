#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
INSTALL_DIR="${MEETING_NOTE_INSTALL_DIR:-${HOME}/Applications}"
SOURCE_APP="${PROJECT_ROOT}/DerivedData/Build/Products/Release/MeetingNote.app"
DESTINATION="${INSTALL_DIR}/MeetingNote.app"

"${SCRIPT_DIR}/build-release.sh"
mkdir -p "${INSTALL_DIR}"

if [[ -e "${DESTINATION}" ]]; then
  BACKUP="${INSTALL_DIR}/MeetingNote.backup.$(date +%Y%m%d-%H%M%S).app"
  mv "${DESTINATION}" "${BACKUP}"
  print "Previous app preserved at ${BACKUP}"
fi

ditto "${SOURCE_APP}" "${DESTINATION}"
open "${DESTINATION}"
print "Installed ${DESTINATION}"
