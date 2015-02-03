#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_api_key="${STEP_CRASHLYTICS_API_KEY}"
CONFIG_build_secret="${STEP_CRASHLYTICS_BUILD_SECRET}"
CONFIG_ipa_pth="${STEP_CRASHLYTICS_IPA_PATH}"
CONFIG_emails_list="${STEP_CRASHLYTICS_EMAIL_LIST}"
CONFIG_group_aliases_list="${STEP_CRASHLYTICS_GROUP_ALIASES_LIST}"
CONFIG_release_notes_pth=""

# STEP_CRASHLYTICS_RELEASE_NOTES -> save to file and provide path

"${THIS_SCRIPT_DIR}/Crashlytics.framework/submit" "${CONFIG_api_key}" "${CONFIG_build_secret}" -ipaPath "${CONFIG_ipa_pth}" -emails "${CONFIG_emails_list}" -notesPath "${CONFIG_release_notes_pth}" -groupAliases ﻿"${CONFIG_group_aliases_list}"
exit $?