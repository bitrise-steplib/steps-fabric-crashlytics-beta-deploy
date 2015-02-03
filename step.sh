#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_api_key="${STEP_CRASHLYTICS_API_KEY}"
CONFIG_build_secret="${STEP_CRASHLYTICS_BUILD_SECRET}"
CONFIG_ipa_pth="${STEP_CRASHLYTICS_IPA_PATH}"
CONFIG_emails_list="${STEP_CRASHLYTICS_EMAIL_LIST}"
CONFIG_group_aliases_list="${STEP_CRASHLYTICS_GROUP_ALIASES_LIST}"
CONFIG_release_notes_pth="${HOME}/app_release_notes.txt"

# STEP_CRASHLYTICS_RELEASE_NOTES -> save to file and provide path
echo "STEP_CRASHLYTICS_RELEASE_NOTES: ${STEP_CRASHLYTICS_RELEASE_NOTES}"
printf "%s" "${STEP_CRASHLYTICS_RELEASE_NOTES}" > "${CONFIG_release_notes_pth}"
echo 'release notes:'
cat "${CONFIG_release_notes_pth}"

# TEST
_TMP_cert_handler_dir_path="${HOME}/steps-download-and-activate-osx-certificate-private-key"
git clone https://github.com/bitrise-io/steps-download-and-activate-osx-certificate-private-key.git "${_TMP_cert_handler_dir_path}"
(
	cd "${_TMP_cert_handler_dir_path}"
	export STEP_CERT_ACTIVATOR_KEYCHAIN_PSW="vagrant"
	export STEP_CERT_ACTIVATOR_KEYCHAIN_PATH="${HOME}/Library/Keychains/login.keychain"
	export STEP_CERT_ACTIVATOR_CERTIFICATES_DIR="${HOME}/cert_activator_certs"
	export STEP_CERT_ACTIVATOR_CERTIFICATE_PASSPHRASE="$BITRISE_CERTIFICATE_PASSPHRASE"
	export STEP_CERT_ACTIVATOR_CERTIFICATE_URL="$BITRISE_CERTIFICATE_URL"

	bash step.sh
)

if [ ! -z "${CONFIG_group_aliases_list}" ] ; then
	_param_groups='-groupAliases ﻿"${CONFIG_group_aliases_list}"'
fi

"${THIS_SCRIPT_DIR}/Crashlytics.framework/submit" \
	"${CONFIG_api_key}" "${CONFIG_build_secret}" \
	-ipaPath "${CONFIG_ipa_pth}" \
	-emails "${CONFIG_emails_list}" \
	-notesPath "${CONFIG_release_notes_pth}" \
	${_param_groups}
exit $?