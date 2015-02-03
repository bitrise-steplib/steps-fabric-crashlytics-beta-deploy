#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_ipa_pth="${STEP_CRASHLYTICS_IPA_PATH}"
CONFIG_emails_list="${STEP_CRASHLYTICS_EMAIL_LIST}"
CONFIG_group_aliases_list="${STEP_CRASHLYTICS_GROUP_ALIASES_LIST}"
CONFIG_release_notes_pth=""

# STEP_CRASHLYTICS_RELEASE_NOTES -> save to file and provide path

"${THIS_SCRIPT_DIR}/Crashlytics.framework/submit" "${CRASHLYTICS_API_KEY}" "${CRASHLYTICS_BUILD_SECRET}" -ipaPath "${CONFIG_ipa_pth}" -emails "${CONFIG_emails_list}" -notesPath "${CONFIG_release_notes_pth}" -groupAliases ﻿"${CONFIG_group_aliases_list}"
exit $?